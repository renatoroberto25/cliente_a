
#!/bin/bash
set -euo pipefail
########################################
# CONFIGURACOES
########################################
FLAG_FILE="/var/lib/tenable/nessusagent/.first-boot-done"
T_KEY="${T_KEY:-45b85b603d4f4ed07d445151eacc6db46715a19318c42da539327de707dedbac}"
T_HOST="${T_HOST:-sensor.cloud.tenable.com}"
T_PORT="${T_PORT:-443}"
T_GROUPS="${T_GROUPS:-LINUX_DEFAULT}"
PROXY_HOST="${PROXY_HOST:-proxy.claro.com.br}"
PROXY_PORT="${PROXY_PORT:-3128}"
HNAME="${HNAME:-$(hostname -s 2>/dev/null || hostname)}"
CLI="/opt/nessus_agent/sbin/nessuscli"
########################################
# FUNCOES
########################################
log() {
    echo "[$1] $2"
}
fail() {
    log "ERRO" "$1"
    exit 1
}
check_direct_access() {
    timeout 10 bash -c "</dev/tcp/${T_HOST}/443" \
        >/dev/null 2>&1
}
check_proxy_access() {
    curl -skI \
        -x "http://${PROXY_HOST}:${PROXY_PORT}" \
        --connect-timeout 15 \
        "https://${T_HOST}" \
        >/dev/null 2>&1
}
########################################
# INICIO
########################################
log INFO "Host........: ${HNAME}"
log INFO "Tenable.....: ${T_HOST}:${T_PORT}"
log INFO "Grupo.......: ${T_GROUPS}"
log INFO "Proxy.......: ${PROXY_HOST}:${PROXY_PORT}"
########################################
# VALIDAR CONECTIVIDADE
########################################
USE_PROXY=0
log INFO "Validando conectividade direta"
if check_direct_access; then
    log INFO "Conectividade direta OK"
else
    log WARN "Sem acesso direto"
    log INFO "Testando proxy corporativo"
    if check_proxy_access; then
        log INFO "Proxy validado"
        USE_PROXY=1
    else
        fail "Sem conectividade direta e sem conectividade via proxy"
    fi
fi
########################################
# DEFINIR CURL
########################################
if [ "$USE_PROXY" -eq 1 ]; then
    CURL_OPTS=(
        -fsSL
        -x "http://${PROXY_HOST}:${PROXY_PORT}"
    )
else
    CURL_OPTS=(
        -fsSL
    )
fi
########################################
# INSTALACAO
########################################
if [ ! -x "$CLI" ]; then
    log INFO "Nessus Agent nao encontrado"
    log INFO "Iniciando instalacao"
    curl "${CURL_OPTS[@]}" \
        -G \
        -H "X-Key: ${T_KEY}" \
        --data-urlencode "name=${HNAME}" \
        --data-urlencode "groups=${T_GROUPS}" \
        "https://${T_HOST}/install/agent" | bash
    sleep 10
else
    log INFO "Nessus Agent ja instalado"
fi
########################################
# VALIDACOES POS-INSTALACAO
########################################
[ -x "$CLI" ] || fail "nessuscli nao encontrado"
########################################
# CONFIGURAR PROXY NO AGENTE
########################################
if [ "$USE_PROXY" -eq 1 ]; then
    log INFO "Configurando proxy no Nessus Agent"
    "$CLI" fix --set proxy="${PROXY_HOST}" || true
    "$CLI" fix --set proxy_port="${PROXY_PORT}" || true
fi
########################################
# INICIAR SERVICO
########################################
log INFO "Iniciando servico"
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable nessusagent >/dev/null 2>&1 || true
    systemctl restart nessusagent >/dev/null 2>&1 || true
else
    service nessusagent start >/dev/null 2>&1 || true
fi
sleep 10
########################################
# STATUS
########################################
STATUS=$("$CLI" agent status 2>&1 || true)
echo "$STATUS"
########################################
# RE-LINK SE NECESSARIO
########################################
if [[ ! "$STATUS" =~ "Linked to: ${T_HOST}:${T_PORT}" ]]; then
    log WARN "Realizando link do agente"
    if [[ "$STATUS" =~ "Linked to:" ]] &&
       [[ ! "$STATUS" =~ "Linked to: None" ]]; then
        log INFO "Desvinculando configuracao anterior"
        "$CLI" agent unlink --force || true
        sleep 5
    fi
    "$CLI" agent link \
        --key="${T_KEY}" \
        --host="${T_HOST}" \
        --port="${T_PORT}" \
        --groups="${T_GROUPS}" \
        --name="${HNAME}"
    sleep 10
fi
########################################
# AGUARDA CONEXAO
########################################
for i in {1..12}; do
    STATUS=$("$CLI" agent status 2>&1 || true)
    if echo "$STATUS" | grep -q "Link status: Connected"; then
        log OK "Agent conectado"
        mkdir -p "$(dirname "$FLAG_FILE")"
        touch "$FLAG_FILE"
        log OK "Flag criada: $FLAG_FILE"
        echo
        echo "==============================="
        echo "STATUS FINAL"
        echo "==============================="
        echo "$STATUS"
        exit 0
    fi
    log INFO "Aguardando conexao (${i}/12)"
    sleep 10
done
########################################
# FALHA
########################################
log ERRO "Agent nao conectou"
echo
echo "==============================="
echo "ULTIMO STATUS"
echo "==============================="
echo "$STATUS"
exit 1