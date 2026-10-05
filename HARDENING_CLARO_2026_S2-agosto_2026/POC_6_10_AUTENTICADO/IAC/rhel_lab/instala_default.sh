#!/bin/bash
set -euo pipefail
FLAG_FILE="/var/lib/tenable/nessusagent/.first-boot-done"
T_KEY="${T_KEY:-45b85b603d4f4ed07d445151eacc6db46715a19318c42da539327de707dedbac}"
T_HOST="${T_HOST:-sensor.cloud.tenable.com}"
T_PORT="${T_PORT:-443}"
T_GROUPS="${T_GROUPS:-LAB_RHEL}"
HNAME="${HNAME:-$(hostname -s 2>/dev/null || hostname)}"
CLI="/opt/nessus_agent/sbin/nessuscli"
log() {
    echo "[$1] $2"
}
fail() {
    log "ERRO" "$1"
    exit 1
}
log INFO "Host........: ${HNAME}"
log INFO "Tenable.....: ${T_HOST}:${T_PORT}"
log INFO "Grupo.......: ${T_GROUPS}"
log INFO "Validando conectividade direta"
if timeout 10 bash -c "</dev/tcp/${T_HOST}/${T_PORT}" >/dev/null 2>&1; then
    log OK "Conectividade direta OK"
else
    fail "Sem conectividade direta com ${T_HOST}:${T_PORT}"
fi
if [ ! -x "$CLI" ]; then
    log INFO "Nessus Agent nao encontrado"
    log INFO "Iniciando instalacao"
    curl -fsSL \
        -G \
        -H "X-Key: ${T_KEY}" \
        --data-urlencode "name=${HNAME}" \
        --data-urlencode "groups=${T_GROUPS}" \
        "https://${T_HOST}/install/agent" | bash
    sleep 10
else
    log INFO "Nessus Agent ja instalado - pulando instalacao"
fi
[ -x "$CLI" ] || fail "nessuscli nao encontrado"
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable nessusagent >/dev/null 2>&1 || true
    systemctl restart nessusagent >/dev/null 2>&1 || true
else
    service nessusagent restart >/dev/null 2>&1 || true
fi
sleep 5
STATUS=$("$CLI" agent status 2>&1 || true)
echo "$STATUS"
if echo "$STATUS" | grep -q "Linked to: ${T_HOST}:${T_PORT}"; then
    log INFO "Agent ja linkado corretamente"
else
    if echo "$STATUS" | grep -q "Linked to:" &&
       ! echo "$STATUS" | grep -q "Linked to: None"; then
        log INFO "Removendo link anterior"
        "$CLI" agent unlink --force || true
        sleep 3
    fi
    log INFO "Linkando agent"
    "$CLI" agent link \
        --key="${T_KEY}" \
        --host="${T_HOST}" \
        --port="${T_PORT}" \
        --groups="${T_GROUPS}" \
        --name="${HNAME}"
    sleep 10
fi
STATUS=$("$CLI" agent status 2>&1 || true)
if echo "$STATUS" | grep -q "Link status: Connected"; then
    log OK "Agent conectado"
    mkdir -p "$(dirname "$FLAG_FILE")"
    touch "$FLAG_FILE"
    echo
    echo "==============================="
    echo "STATUS FINAL"
    echo "==============================="
    echo "$STATUS"
    exit 0
else
    log ERRO "Agent linkado, mas ainda nao conectado"
    echo
    echo "==============================="
    echo "STATUS FINAL"
    echo "==============================="
    echo "$STATUS"
    exit 1
fi