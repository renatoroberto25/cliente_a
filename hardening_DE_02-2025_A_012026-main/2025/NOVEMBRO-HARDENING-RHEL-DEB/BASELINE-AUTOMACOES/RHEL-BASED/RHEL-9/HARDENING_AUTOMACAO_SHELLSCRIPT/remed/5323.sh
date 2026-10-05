#!/usr/bin/env bash

echo -e "\n 177 Ensure pam_pwquality module is enabled"

arquivo_conf="/etc/authselect/authselect.conf"
modulo="pwquality"

if [[ ! -f "$arquivo_conf" ]]; then
    echo "[❗] Arquivo $arquivo_conf não encontrado. Este sistema usa authselect?"
    exit 0
fi

perfil=$(awk 'NR==1 {print $1}' "$arquivo_conf")
caminho="/usr/share/authselect/default/$perfil"

if grep -q "pam_${modulo}\.so" "$caminho"/{password,system}-auth 2>/dev/null; then
    echo "[✅] pam_${modulo}.so está presente no perfil $perfil."
else
    echo "[✖] pam_${modulo}.so não encontrado no perfil $perfil."
fi