#!/usr/bin/env bash

# Este script aplica as configurações recomendadas para log_martians.
# Baseado no procedimento de remediação:
# 1. Define os parâmetros no arquivo /etc/sysctl.d/60-netipv4_sysctl.conf (para IPv4)
# 2. Aplica as configurações ativamente no sistema com sysctl -w
# 3. Força a atualização das rotas para garantir a aplicação imediata

# Função para configurar parâmetros de rede
configurar_rede() {
    local parametro=$1
    local valor=$2
    local arquivo_conf="/etc/sysctl.d/60-${parametro//./_}.conf"

    # Adiciona a configuração ao arquivo
    if printf '%s\n' "${parametro} = ${valor}" >> "${arquivo_conf}"; then
        echo "**✅ APROVADO **: Configuração de ${parametro} adicionada ao arquivo ${arquivo_conf}."

        # Aplica a configuração ativa
        if sysctl -w "${parametro}=${valor}"; then
            echo "**✅ APROVADO **: ${parametro} configurado com sucesso."
        else
            echo "**⚠️[REPROVADO] **: Erro ao configurar ${parametro}."
        fi
    else
        echo "**⚠️[REPROVADO] **: Erro ao escrever no arquivo ${arquivo_conf}."
    fi
}

# Configura parâmetros para IPv4
configurar_rede "net.ipv4.conf.all.log_martians" 1
configurar_rede "net.ipv4.conf.default.log_martians" 1

# Força a atualização das rotas para IPv4
sysctl -w net.ipv4.route.flush=1
