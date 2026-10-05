#!/usr/bin/env bash

log()  { echo "[✅ SUCESSO] $1"; }
err()  { echo "[❌ FALHA] $1"; }
warn() { echo "[⚠️ AVISO] $1"; }

echo "124 Ensure ip forwarding is disabled"
echo

remediar_parametro() {
    local parametro="$1"
    local valor_esperado="$2"
    local arquivo="/etc/sysctl.d/60-net_forwarding.conf"

    echo "- Configurando $parametro para $valor_esperado..."

    # Define no arquivo
    if grep -q "^$parametro" "$arquivo" 2>/dev/null; then
        sed -i "s/^$parametro.*/$parametro = $valor_esperado/" "$arquivo" && \
        log "Atualizado no arquivo: $parametro = $valor_esperado" || err "Erro ao atualizar $parametro no arquivo"
    else
        echo "$parametro = $valor_esperado" >> "$arquivo" && \
        log "Adicionado ao arquivo: $parametro = $valor_esperado" || err "Erro ao adicionar $parametro no arquivo"
    fi

    # Aplica ao vivo
    if sysctl -w "$parametro=$valor_esperado" >/dev/null 2>&1; then
        log "$parametro aplicado via sysctl"
    else
        err "Falha ao aplicar $parametro com sysctl"
    fi
}

# Executa as remediações
remediar_parametro "net.ipv4.ip_forward" 0

# Verifica se IPv6 está presente
if [ -f /proc/net/if_inet6 ]; then
    remediar_parametro "net.ipv6.conf.all.forwarding" 0
else
    warn "IPv6 não detectado — parâmetro net.ipv6.conf.all.forwarding ignorado"
fi

# Força flush de rotas
echo
echo "- Forçando atualização das rotas..."
sysctl -w net.ipv4.route.flush=1 >/dev/null && log "Rotas IPv4 atualizadas"
sysctl -w net.ipv6.route.flush=1 >/dev/null && log "Rotas IPv6 atualizadas"

echo
log "Remediação de rede concluída com sucesso."
