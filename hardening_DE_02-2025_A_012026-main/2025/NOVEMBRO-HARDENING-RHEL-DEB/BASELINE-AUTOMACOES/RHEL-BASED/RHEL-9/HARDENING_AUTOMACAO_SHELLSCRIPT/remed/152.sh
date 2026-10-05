#!/usr/bin/env bash

# Exibir o conteúdo atual antes da alteração
echo "Conteúdo atual de /etc/sysctl.d/60-kernel_sysctl.conf:"
grep -i "kernel.yama" /etc/sysctl.d/60-kernel_sysctl.conf

# Atualizar ou adicionar o parâmetro no arquivo
if grep -q "^kernel.yama.ptrace_scope" /etc/sysctl.d/60-kernel_sysctl.conf; then
    sed -i "s/^kernel.yama.ptrace_scope.*/kernel.yama.ptrace_scope=1/" /etc/sysctl.d/60-kernel_sysctl.conf
    echo "Parâmetro atualizado em /etc/sysctl.d/60-kernel_sysctl.conf"
else
    echo "kernel.yama.ptrace_scope=1" >> /etc/sysctl.d/60-kernel_sysctl.conf
    echo "Parâmetro adicionado em /etc/sysctl.d/60-kernel_sysctl.conf"
fi

# Aplicar a alteração na configuração do kernel em execução
sysctl -w kernel.yama.ptrace_scope=1

# Exibir o conteúdo após a alteração
echo "Conteúdo após a alteração de /etc/sysctl.d/60-kernel_sysctl.conf:"
grep -i "kernel.yama" /etc/sysctl.d/60-kernel_sysctl.conf

echo "Remediação concluída."
