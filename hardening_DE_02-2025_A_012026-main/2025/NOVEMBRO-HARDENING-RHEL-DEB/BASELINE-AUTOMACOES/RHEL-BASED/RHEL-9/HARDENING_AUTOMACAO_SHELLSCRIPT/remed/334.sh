#!/usr/bin/env bash

# Função para configurar parâmetros de rede
configurar_rede() {
    local parametro=$1
    local valor=$2
    local arquivo_conf="/etc/sysctl.d/60-netipv4_sysctl.conf"

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

# Configura o parâmetro de rede IPv4
configurar_rede "net.ipv4.icmp_echo_ignore_broadcasts" 1

# Força a atualização das rotas
sysctl -w net.ipv4.route.flush=1
