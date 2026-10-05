#!/usr/bin/env bash

# Função para configurar parâmetros de rede
configurar_rede() {
    local parametro=$1
    local valor=$2
    local arquivo_conf="/etc/sysctl.d/60-net${parametro%%.*}_sysctl.conf"

    # Adiciona a configuração ao arquivo
    if printf '%s\n' "${parametro} = ${valor}" >> "${arquivo_conf}"; then
        echo "[✅ SUCESSO]"

        # Aplica a configuração ativa
        if sysctl -w "${parametro}=${valor}"; then
            echo "[✅ SUCESSO]"
        else
            echo "[❌ FALHA]"
        fi
    else
        echo "[❌ FALHA]"
    fi
}

# Configura parâmetros para IPv4
configurar_rede "net.ipv4.conf.all.accept_redirects" 0
configurar_rede "net.ipv4.conf.default.accept_redirects" 0

# Configura parâmetros para IPv6, se estiver habilitado
if [ -d /proc/sys/net/ipv6 ]; then
    configurar_rede "net.ipv6.conf.all.accept_redirects" 0
    configurar_rede "net.ipv6.conf.default.accept_redirects" 0
fi

# Força a atualização das rotas
sysctl -w net.ipv4.route.flush=1
[ -d /proc/sys/net/ipv6 ] && sysctl -w net.ipv6.route.flush=1