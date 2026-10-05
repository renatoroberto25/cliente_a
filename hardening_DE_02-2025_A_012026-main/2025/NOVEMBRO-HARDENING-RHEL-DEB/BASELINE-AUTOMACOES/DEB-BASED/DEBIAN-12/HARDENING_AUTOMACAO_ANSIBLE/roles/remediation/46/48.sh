#!/usr/bin/env bash
echo "[48] Corrigir restrição de core dumps"

# Verifica /etc/security/limits.conf e limits.d/*
limits_check=$(grep -Ps -- '^[[:space:]]*\*[[:space:]]+hard[[:space:]]+core[[:space:]]+0\b' /etc/security/limits.conf /etc/security/limits.d/* 2>/dev/null)
if [ -z "$limits_check" ]; then
    echo "⚠️ Ajustando /etc/security/limits.conf para core dumps..."
    cp /etc/security/limits.conf /etc/security/limits.conf.bak_$(date +%F_%H%M)
    echo "* hard core 0" >> /etc/security/limits.conf
    echo "✅ Adicionado em /etc/security/limits.conf"
else
    echo "✅ Já configurado em limits"
fi

# Verifica sysctl fs.suid_dumpable
if [ "$(sysctl -n fs.suid_dumpable 2>/dev/null)" -ne 0 ]; then
    echo "⚠️ Corrigindo fs.suid_dumpable..."
    cp /etc/sysctl.conf /etc/sysctl.conf.bak_$(date +%F_%H%M)
    sysctl -w fs.suid_dumpable=0
    grep -q '^fs.suid_dumpable' /etc/sysctl.conf && \
        sed -i 's/^fs.suid_dumpable.*/fs.suid_dumpable=0/' /etc/sysctl.conf || \
        echo "fs.suid_dumpable=0" >> /etc/sysctl.conf
    echo "✅ Corrigido"
else
    echo "✅ Já está correto"
fi