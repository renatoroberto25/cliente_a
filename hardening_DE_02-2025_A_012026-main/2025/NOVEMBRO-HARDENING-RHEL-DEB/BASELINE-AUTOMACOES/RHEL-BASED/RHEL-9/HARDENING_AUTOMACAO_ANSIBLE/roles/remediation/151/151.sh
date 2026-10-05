#!/usr/bin/env bash

# Definir o nome e valor do parâmetro a ser configurado
kernel_param="kernel.randomize_va_space"
param_value="2"
sysctl_conf="/etc/sysctl.d/60-kernel_sysctl.conf"

# Verifica se o arquivo /etc/sysctl.d/60-kernel_sysctl.conf existe, caso contrário, cria-o
if [ ! -f "$sysctl_conf" ]; then
    touch "$sysctl_conf"
fi

# Adiciona a linha ao arquivo de configuração
if ! grep -q "^$kernel_param=" "$sysctl_conf"; then
    echo "$kernel_param = $param_value" >> "$sysctl_conf"
    echo "Configuração $kernel_param = $param_value adicionada ao arquivo $sysctl_conf"
else
    echo "A configuração $kernel_param já está presente em $sysctl_conf"
fi

# Aplica a configuração imediatamente
sysctl -w "$kernel_param=$param_value"
echo "Parâmetro $kernel_param configurado com sucesso para $param_value."

# Verificar a configuração ativa
current_value=$(sysctl -n "$kernel_param")
if [ "$current_value" -eq "$param_value" ]; then
    echo "O valor atual de $kernel_param está corretamente configurado como $current_value"
else
    echo "Falha ao configurar o parâmetro $kernel_param para o valor $param_value"
fi
