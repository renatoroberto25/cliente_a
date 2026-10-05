#!/usr/bin/env bash

# Função para corrigir permissões de um arquivo, apenas se necessário
corrigir_permissoes() {
    local path=$1
    local owner=$2
    local group=$3
    local mode=$4
    
    if [[ -e "$path" ]]; then
        local current_owner=$(stat -c %U "$path")
        local current_group=$(stat -c %G "$path")
        local current_mode=$(stat -c %a "$path")
        
        if [[ "$current_owner" != "$owner" || "$current_group" != "$group" ]]; then
            chown "$owner":"$group" "$path"
            echo "[✅ SUCESSO]"
        fi
        
        if [[ "$current_mode" != "$mode" ]]; then
            chmod "$mode" "$path"
            echo "[✅ SUCESSO]"
        fi
    else
        echo "[❌ FALHA]"
    fi
}

# Determinar grupo correto apenas para Servidores baseados em RHEL e família RHEL
if [[ -f /etc/oracle-release || -f /etc/redhat-release ]]; then
    if getent group daemon &>/dev/null; then
        l_group="daemon"
    else
        l_group="root"
    fi
else
    echo "❌ **REPROVADO**: Este script é exclusivo para Servidores baseados em RHEL/RHEL."
    exit 1
fi

# Criar e corrigir permissões de /etc/at.allow, se necessário
if [[ ! -e "/etc/at.allow" ]]; then
    touch /etc/at.allow
    echo "[✅ SUCESSO]"
fi
corrigir_permissoes /etc/at.allow root "$l_group" 640

# Corrigir permissões de /etc/at.deny, se existir
if [[ -e "/etc/at.deny" ]]; then
    corrigir_permissoes /etc/at.deny root "$l_group" 640
fi
