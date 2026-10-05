#!/usr/bin/env bash

log() {
    echo "[+] $1"
}

err() {
    echo "[-] $1"
}


# Verifica se o GDM está instalado
if ! command -v gdm >/dev/null 2>&1; then
    echo "GDM não está instalado."
    exit 0
fi

# Verifica se a configuração está presente
if grep -Eis '^\s*Enable\s*=\s*true' /etc/gdm/custom.conf >/dev/null 2>&1; then
    # Remove a linha com a configuração Enable=true
    sed -i '/^\s*Enable\s*=\s*true/d' /etc/gdm/custom.conf
    log "Remediation aplicada: Linha 'Enable=true' removida de /etc/gdm/custom.conf."
else
    err "Nada a corrigir: A configuração 'Enable=true' não foi encontrada."
fi
