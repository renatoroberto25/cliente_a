#!/usr/bin/env bash

echo "38 - 39 Configure Package Repositories"

CONFIG_FILE="/etc/dnf/dnf.conf"

echo "38 Ensure repo_gpgcheck is globally activated - hardening_full"
# Garantir que repo_gpgcheck está ativado globalmente
echo "Ativando repo_gpgcheck globalmente..."
if grep -q "^repo_gpgcheck" "$CONFIG_FILE"; then
    if sed -i 's/^repo_gpgcheck.*/repo_gpgcheck=1/' "$CONFIG_FILE"; then
        echo "[✅ SUCESSO]: repo_gpgcheck ativado no arquivo $CONFIG_FILE."
    else
        echo "[❌ FALHA]"
    fi
else
    if echo "repo_gpgcheck=1" >> "$CONFIG_FILE"; then
        echo "[✅ SUCESSO]: repo_gpgcheck adicionado e ativado no arquivo $CONFIG_FILE."
    else
        echo "[❌ FALHA]"
    fi
fi