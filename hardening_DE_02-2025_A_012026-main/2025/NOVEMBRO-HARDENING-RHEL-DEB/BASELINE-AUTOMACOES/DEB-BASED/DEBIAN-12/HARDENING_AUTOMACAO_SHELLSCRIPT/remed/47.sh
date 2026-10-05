#!/usr/bin/env bash
echo "[47] Corrigir parâmetro ptrace_scope"

val=$(sysctl -n kernel.yama.ptrace_scope 2>/dev/null || echo 0)
if [[ ! "$val" =~ ^[1-3]$ ]]; then
    echo "⚠️ Corrigindo kernel.yama.ptrace_scope..."
    cp /etc/sysctl.conf /etc/sysctl.conf.bak_$(date +%F_%H%M)
    sysctl -w kernel.yama.ptrace_scope=1
    grep -q '^kernel.yama.ptrace_scope' /etc/sysctl.conf && \
        sed -i 's/^kernel.yama.ptrace_scope.*/kernel.yama.ptrace_scope=1/' /etc/sysctl.conf || \
        echo "kernel.yama.ptrace_scope=1" >> /etc/sysctl.conf
    echo "✅ Corrigido"
else
    echo "✅ Já está correto"
fi