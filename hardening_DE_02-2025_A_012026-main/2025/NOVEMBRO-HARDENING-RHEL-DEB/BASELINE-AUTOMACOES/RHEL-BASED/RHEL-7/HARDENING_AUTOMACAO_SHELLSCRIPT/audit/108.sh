#!/usr/bin/env bash
echo "[108–133] Verificações de nftables, iptables e ip6tables"

# 108 - Ensure nftables is installed
echo "[108] Verifique se o nftables está instalado"
rpm -q nftables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 109 - Ensure firewalld is either not installed or masked with nftables
echo "[109] Verifique se o firewalld está desabilitado ao usar nftables"
if systemctl is-enabled firewalld &>/dev/null || systemctl is-active firewalld &>/dev/null; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

# 110 - Ensure iptables-services not installed with nftables
echo "[110] Verifique se iptables-services não está instalado junto com nftables"
if rpm -q nftables &>/dev/null && rpm -q iptables-services &>/dev/null; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

# 111 - Ensure iptables are flushed with nftables
echo "[111] Verifique se iptables está limpo (sem regras) quando nftables é utilizado"
iptables -L 2>/dev/null | grep -qvE "Chain|target|policy" && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[ICMP] Verifique se timestamp-request está configurado para drop"
( nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-request[[:space:]]+drop' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[ICMP] Verifique se timestamp-reply está configurado para drop"
( nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-reply[[:space:]]+drop' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 112 - Ensure an nftables table exists
echo "[112] Verifique se há tabela configurada no nftables"
nft list tables 2>/dev/null | grep -q . && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 113 - Ensure nftables base chains exist
echo "[113] Verifique se as cadeias base do nftables existem"
nft list chains 2>/dev/null | grep -Eq "hook input|hook forward|hook output" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 114 - Ensure nftables loopback traffic is configured
echo "[114] Verifique se o tráfego de loopback está permitido no nftables"
nft list ruleset 2>/dev/null | grep -Eq "iif lo accept" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 115 - Ensure nftables outbound and established connections are configured
echo "[115] Verifique se conexões estabelecidas e saídas estão permitidas"
nft list ruleset 2>/dev/null | grep -Eq "ct state (related,established|established,related)" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 116 - Ensure nftables default deny firewall policy
echo "[116] Verifique se a política padrão do nftables é de negação"
nft list ruleset 2>/dev/null | grep -Eq "policy drop" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 117 - Ensure nftables service is enabled
echo "[117] Verifique se o serviço nftables está habilitado"
systemctl is-enabled nftables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 118 - Ensure nftables rules are permanent
echo "[118] Verifique se regras do nftables estão persistentes"
grep -q "include" /etc/sysconfig/nftables.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 119 - Ensure iptables packages are installed
echo "[119] Verifique se iptables está instalado"
rpm -q iptables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 120 - Ensure nftables is not installed with iptables
echo "[120] Verifique se nftables não está ativo junto com iptables"
if systemctl is-active nftables &>/dev/null; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

# 121 - Ensure firewalld is either not installed or masked with iptables
echo "[121] Verifique se firewalld não está ativo junto com iptables"
if systemctl is-active firewalld &>/dev/null; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

# 122 - Ensure iptables loopback traffic is configured
echo "[122] Verifique se iptables permite tráfego loopback"
iptables -L INPUT -v -n 2>/dev/null | grep -q "lo" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 123 - Ensure iptables outbound and established connections are configured
echo "[123] Verifique se iptables permite conexões estabelecidas e saídas"
iptables -L -v -n 2>/dev/null | grep -Eq "ESTABLISHED,RELATED" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 124 - Ensure iptables rules exist for all open ports
echo "[124] Verifique se iptables possui regras para todas as portas abertas"
ss -tuln | awk 'NR>1 {print $5}' | cut -d: -f2 | sort -u | while read port; do
  iptables -L INPUT -v -n 2>/dev/null | grep -q "$port" || { echo "⚠️ Porta $port sem regra explícita"; exit 1; }
done && echo "✅ APROVADO"

# 125 - Ensure iptables default deny firewall policy
echo "[125] Verifique se política padrão do iptables é de negação"
iptables -L INPUT 2>/dev/null | grep -q "policy DROP" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 126 - Ensure iptables rules are saved
echo "[126] Verifique se as regras do iptables estão salvas"
[ -s /etc/sysconfig/iptables ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 127 - Ensure iptables is enabled and running
echo "[127] Verifique se o iptables está habilitado e em execução"
systemctl is-enabled iptables &>/dev/null && systemctl is-active iptables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 128 - Ensure ip6tables loopback traffic is configured
echo "[128] Verifique se ip6tables permite tráfego loopback"
ip6tables -L INPUT -v -n 2>/dev/null | grep -q "lo" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 129 - Ensure ip6tables outbound and established connections are configured
echo "[129] Verifique se ip6tables permite conexões estabelecidas e saídas"
ip6tables -L -v -n 2>/dev/null | grep -Eq "ESTABLISHED,RELATED" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 130 - Ensure ip6tables firewall rules exist for all open ports
echo "[130] Verifique se ip6tables possui regras para portas IPv6 abertas"
ss -tuln | grep -E "::" | awk '{print $5}' | cut -d: -f2 | sort -u | while read port; do
  ip6tables -L INPUT -v -n 2>/dev/null | grep -q "$port" || { echo "⚠️ Porta IPv6 $port sem regra explícita"; exit 1; }
done && echo "✅ APROVADO"

# 131 - Ensure ip6tables default deny firewall policy
echo "[131] Verifique se política padrão do ip6tables é de negação"
ip6tables -L INPUT 2>/dev/null | grep -q "policy DROP" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 132 - Ensure ip6tables rules are saved
echo "[132] Verifique se as regras do ip6tables estão salvas"
[ -s /etc/sysconfig/ip6tables ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 133 - Ensure ip6tables is enabled and running
echo "[133] Verifique se o ip6tables está habilitado e em execução"
systemctl is-enabled ip6tables &>/dev/null && systemctl is-active ip6tables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[ICMP] Verifique se timestamp-request está configurado para drop"
( nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-request[[:space:]]+drop' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[ICMP] Verifique se timestamp-reply está configurado para drop"
( nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-reply[[:space:]]+drop' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
