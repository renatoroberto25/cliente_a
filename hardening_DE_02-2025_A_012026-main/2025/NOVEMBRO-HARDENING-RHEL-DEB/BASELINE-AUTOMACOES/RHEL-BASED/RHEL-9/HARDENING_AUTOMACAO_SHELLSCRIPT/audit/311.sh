#!/usr/bin/env bash

echo " Verificando status do IPv6..."

# Verifica se o IPv6 está desabilitado no nível do kernel
if grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable; then
echo "📌 IPv6 está **desabilitado** no kernel."
else
echo "📌 IPv6 está **habilitado** no kernel."
fi

# Verifica se o IPv6 está desabilitado via sysctl
ipv6_all=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)
ipv6_default=$(sysctl -n net.ipv6.conf.default.disable_ipv6 2>/dev/null)

if [[ "$ipv6_all" == "1" && "$ipv6_default" == "1" ]]; then
echo "📌 IPv6 está **desabilitado** via sysctl."
elif [[ "$ipv6_all" == "0" && "$ipv6_default" == "0" ]]; then
echo "📌 IPv6 está **habilitado** via sysctl."
else
echo "📌 IPv6 está **parcialmente desabilitado** via sysctl."
fi

echo "\nℹ️  Configuração do IPv6 depende da política local. Ajuste conforme necessário."
