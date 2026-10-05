#!/usr/bin/env bash

# Verifica se o pacote bluez está instalado
verificar_pacote_bluez() {
    if rpm -q bluez &>/dev/null; then
echo "⚠️[REPROVADO] : O pacote 'bluez' está instalado. Considere removê-lo se não for necessário."
    else
echo "✅ [APROVADO]: O pacote 'bluez' não está instalado."
    fi
}

# Verifica se o serviço bluetooth está ativo e habilitado
verificar_servico_bluetooth() {
    local servico="bluetooth.service"
    
    if systemctl list-unit-files --type=service --no-pager | grep -q "^$servico"; then
        # Verifica se está habilitado
        if systemctl is-enabled --quiet "$servico"; then
echo "⚠️[REPROVADO] : Serviço $servico está HABILITADO. Por favor, desative-o."
        else
echo "✅ [APROVADO]: Serviço $servico não está habilitado."
        fi
        
        # Verifica se está ativo
        if systemctl is-active --quiet "$servico"; then
echo "⚠️[REPROVADO] : Serviço $servico está ATIVO. Por favor, pare-o se não for necessário."
        else
echo "✅ [APROVADO]: Serviço $servico não está ativo."
        fi
    else
echo "✅ [APROVADO]: Serviço $servico não está instalado."
    fi
}

# Executar verificações
verificar_pacote_bluez
verificar_servico_bluetooth
