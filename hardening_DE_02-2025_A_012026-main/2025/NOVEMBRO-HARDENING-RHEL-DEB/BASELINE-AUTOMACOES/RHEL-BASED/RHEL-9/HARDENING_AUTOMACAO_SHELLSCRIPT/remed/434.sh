#!/usr/bin/env bash

echo -e "\n[142] Remediação – Configurar tráfego de loopback no nftables"

# Detecta se firewalld está ativo
if systemctl is-enabled firewalld.service &>/dev/null; then
    echo "⚠️ Firewalld está habilitado – remediação não se aplica."
    echo "✅ Remediação não executada (NA)"
    exit 0
fi

# Verifica se nftables está ativo
if ! systemctl is-enabled nftables.service &>/dev/null; then
    echo "❌ Serviço 'nftables' não está habilitado – não é possível aplicar regras."
    exit 1
fi

# Regras de loopback (input iif lo accept)
if ! nft list ruleset | awk '/hook input/,/}/' | grep -Pq '\biif\s+lo\s+accept\b'; then
    echo "⚠️ Adicionando regra para aceitar tráfego da interface loopback (lo)..."
    nft add rule inet filter input iif lo accept && echo "[✅ SUCESSO]: loopback input accept"
else
    echo "[✅ SUCESSO]: Regra 'iif lo accept' já presente"
fi

# IPv4 – drop de pacotes de spoofing 127.0.0.0/8
if ! nft list ruleset | grep -Pq 'ip\s+saddr\s+127\.0\.0\.0/8\s+.*\s+drop'; then
    echo "⚠️ Adicionando regra para bloquear pacotes spoofados (127.0.0.0/8)..."
    nft add rule inet filter input ip saddr 127.0.0.0/8 counter drop && echo "[✅ SUCESSO]: IPv4 drop configurado"
else
    echo "[✅ SUCESSO]: Regra de drop IPv4 já presente"
fi

# IPv6 – se IPv6 estiver ativo, aplica regra ::1
if grep -q '^0$' /sys/module/ipv6/parameters/disable; then
    if ! nft list ruleset | grep -Pq 'ip6\s+saddr\s+::1\s+.*\s+drop'; then
        echo "⚠️ Adicionando regra para bloquear pacotes spoofados IPv6 (::1)..."
        nft add rule inet filter input ip6 saddr ::1 counter drop && echo "[✅ SUCESSO]: IPv6 drop configurado"
    else
        echo "[✅ SUCESSO]: Regra de drop IPv6 já presente"
    fi
else
    echo "ℹ️ IPv6 está desabilitado – regra ::1 não necessária."
fi

# Salva persistência
nft list ruleset > /etc/sysconfig/nftables.conf && echo "[✅ SUCESSO]: Regras salvas"