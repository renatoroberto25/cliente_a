#!/usr/bin/env bash
echo "[46] Corrigir randomização do espaço de endereços (ASLR)"

if [ "$(sysctl -n kernel.randomize_va_space 2>/dev/null)" -ne 2 ]; then
    echo "⚠️ Corrigindo kernel.randomize_va_space..."
    cp /etc/sysctl.conf /etc/sysctl.conf.bak_$(date +%F_%H%M)
    sysctl -w kernel.randomize_va_space=2
    grep -q '^kernel.randomize_va_space' /etc/sysctl.conf && \
        sed -i 's/^kernel.randomize_va_space.*/kernel.randomize_va_space=2/' /etc/sysctl.conf || \
        echo "kernel.randomize_va_space=2" >> /etc/sysctl.conf
    echo "✅ Corrigido"
else
    echo "✅ Já está correto"
fi