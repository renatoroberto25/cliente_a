#!/usr/bin/env bash

# Este script aplica as configurações recomendadas para tcp_syncookies.
# Baseado no procedimento de remediação:
# 1. Define o parâmetro no arquivo /etc/sysctl.d/60-netipv4_tcp_syncookies.conf.
# 2. Aplica a configuração ativa no kernel.
# 3. Força a atualização das rotas.

# Nome do parâmetro e valor
PARAM="net.ipv4.tcp_syncookies"
VALUE=1
CONF_FILE="/etc/sysctl.d/60-netipv4_tcp_syncookies.conf"

# Adiciona a configuração ao arquivo
if printf '%s\n' "${PARAM} = ${VALUE}" >> "${CONF_FILE}"; then
    echo "**✅ APROVADO**: Configuração de ${PARAM} adicionada ao arquivo ${CONF_FILE}."
    
    # Aplica a configuração ativa
    if sysctl -w "${PARAM}=${VALUE}"; then
        echo "**✅ APROVADO**: ${PARAM} configurado com sucesso."
    else
        echo "**⚠️[REPROVADO]**: Erro ao configurar ${PARAM}."
    fi
else
    echo "**⚠️[REPROVADO]**: Erro ao escrever no arquivo ${CONF_FILE}."
fi

# Força a atualização das rotas
sysctl -w net.ipv4.route.flush=1
if [ $? -eq 0 ]; then
    echo "**✅ APROVADO**: Rotas de rede atualizadas com sucesso."
else
    echo "**⚠️[REPROVADO]**: Erro ao atualizar as rotas."
fi