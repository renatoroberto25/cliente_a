#!/usr/bin/env bash

# Instalação e configuração inicial do AIDE

echo "214 Ensure AIDE is installed"

# Verifica e instala o AIDE, se necessário
if rpm -q aide &>/dev/null; then
    echo "✅ AIDE já está instalado."
else
    echo "Instalando o AIDE..."
    if dnf install -y aide &>/dev/null; then
        echo "✅ AIDE instalado com sucesso."
    else
        echo "❌ ERRO: Falha ao instalar o AIDE."
        exit 1
    fi
fi