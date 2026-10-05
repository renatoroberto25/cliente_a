#!/usr/bin/env bash

echo -e "\n 29 Ensure gpgcheck is globally activated"
# Backup antes de alterar
cp -f /etc/yum.conf /etc/yum.conf.bkp_$(date +%F_%H%M)
cp -rf /etc/yum.repos.d /etc/yum.repos.d.bkp_$(date +%F_%H%M)

# Ativar gpgcheck no yum.conf
if grep -q '^\s*gpgcheck\s*=' /etc/yum.conf; then
    sed -ri 's/^\s*gpgcheck\s*=.*/gpgcheck=1/' /etc/yum.conf
else
    echo "gpgcheck=1" >> /etc/yum.conf
fi

# Corrigir nos repositórios
find /etc/yum.repos.d -type f -name "*.repo" -exec \
    sed -ri 's/^\s*gpgcheck\s*=.*/gpgcheck=1/' {} +

# Confirmar resultado
grep -RP '^\s*gpgcheck\s*=' /etc/yum.conf /etc/yum.repos.d | grep -v "gpgcheck=1" >/dev/null && \
echo "⚠️ Correção parcial — revise repositórios manuais" || echo "✅ Correção aplicada com sucesso"
