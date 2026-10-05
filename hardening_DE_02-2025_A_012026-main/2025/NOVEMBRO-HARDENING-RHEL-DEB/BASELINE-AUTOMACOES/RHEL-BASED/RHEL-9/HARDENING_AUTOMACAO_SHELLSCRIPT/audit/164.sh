#!/usr/bin/env bash

# Executar o comando grep
resultado=$(grep -Pi -- '^\h*mac\h*=\h*([^#\n\r]+)?-64\b' /etc/crypto-policies/state/CURRENT.pol)

# Verificar se o resultado está vazio
if [ -z "$resultado" ]; then
echo "✅ [APROVADO]: Configuração não contem MACS abaixo de 128 bits."
else
echo "⚠️[REPROVADO]: Configuração incorreta encontrada:"
    grep -Pi -- '^\h*mac\h*=\h*([^#\n\r]+)?-64\b' /etc/crypto-policies/state/CURRENT.pol

fi
