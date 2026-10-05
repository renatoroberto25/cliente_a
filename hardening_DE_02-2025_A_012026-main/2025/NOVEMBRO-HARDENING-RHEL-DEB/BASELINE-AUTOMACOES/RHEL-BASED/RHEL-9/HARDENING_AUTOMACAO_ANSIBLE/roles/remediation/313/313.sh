#!/usr/bin/env bash

# Função para parar e remover o pacote bluez, se possível
remover_pacote_bluez() {
    if rpm -q bluez &>/dev/null; then
        echo "ℹ️ Removendo o pacote 'bluez'..."
        dnf remove -y bluez && echo "[✅ SUCESSO]"
    else
        echo "[✅ SUCESSO]"
    fi
}

# Função para parar e mascarar o serviço bluetooth, se necessário
parar_mascarar_bluetooth() {
    local servico="bluetooth.service"
    
    if systemctl list-unit-files --type=service --no-pager | grep -q "^$servico"; then
        echo "ℹ️ Parando o serviço $servico..."
        systemctl stop "$servico" && echo "[✅ SUCESSO]"
        
        echo "ℹ️ Mascarando o serviço $servico..."
        systemctl mask "$servico" && echo "[✅ SUCESSO]"
    else
        echo "[✅ SUCESSO]"
    fi
}

# Executar remediação
if rpm -q bluez &>/dev/null; then
    remover_pacote_bluez
else
    parar_mascarar_bluetooth
fi
