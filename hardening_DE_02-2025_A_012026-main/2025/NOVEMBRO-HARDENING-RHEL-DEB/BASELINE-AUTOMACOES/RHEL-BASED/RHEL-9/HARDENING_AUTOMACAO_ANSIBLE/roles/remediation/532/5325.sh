#!/usr/bin/env bash

echo -e "\n[179] Certificar que o módulo pam_unix está habilitado no perfil do authselect"

modulo="unix"
arquivo_conf="/etc/authselect/authselect.conf"

if [[ ! -f "$arquivo_conf" ]]; then
    echo "[❗] Arquivo $arquivo_conf não encontrado. Este sistema usa authselect?"
    exit 0
fi

perfil=$(awk 'NR==1 {print $1}' "$arquivo_conf")
caminho="/usr/share/authselect/default/$perfil"

if grep -q "pam_${modulo}\.so" "$caminho"/{password,system}-auth 2>/dev/null; then
    echo "[✅] pam_${modulo}.so já está presente no perfil $perfil."
else
    echo "[✖] pam_${modulo}.so não encontrado no perfil $perfil."
    echo "[⚠️] Recomenda-se recriar o perfil com: authselect select custom/$perfil with-* --force"
fi