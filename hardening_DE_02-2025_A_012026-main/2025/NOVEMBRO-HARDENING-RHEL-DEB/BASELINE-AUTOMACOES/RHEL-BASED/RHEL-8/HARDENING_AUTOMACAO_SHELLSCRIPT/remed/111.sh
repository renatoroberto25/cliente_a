#!/usr/bin/env bash
echo "[111 - 118] Remediação de parâmetros de rede (IPv4 - sysctl)"

backup="/etc/sysctl.conf.bak_$(date +%F_%H-%M-%S)"
cp -p /etc/sysctl.conf "$backup" && echo " Backup criado: $backup"

declare -A sysctl_config=(
  [net.ipv4.ip_forward]=0
  [net.ipv4.conf.all.send_redirects]=0
  [net.ipv4.icmp_ignore_bogus_error_responses]=1
  [net.ipv4.icmp_echo_ignore_broadcasts]=1
  [net.ipv4.conf.all.accept_redirects]=0
  [net.ipv4.conf.all.secure_redirects]=0
  [net.ipv4.conf.all.rp_filter]=1
  [net.ipv4.conf.all.accept_source_route]=0
)

for param in "${!sysctl_config[@]}"; do
  valor="${sysctl_config[$param]}"
  echo "$param = $valor" >> /etc/sysctl.conf
  sysctl -w "$param=$valor" &>/dev/null
  echo "✅ Corrigido: $param = $valor"
done

echo "[ICMP] Garantir DROP para timestamp-request e timestamp-reply"

# 1. Garantir tabela e chain
nft list table inet filter >/dev/null 2>&1 || nft add table inet filter
nft list chain inet filter input >/dev/null 2>&1 \
  || nft add chain inet filter input { type filter hook input priority 0\; }

# 2. Remover TODAS as instâncias antigas
nft --handle list chain inet filter input \
 | grep -Ei 'icmp[[:space:]]+type[[:space:]]+timestamp-(request|reply)' \
 | awk '{print $NF}' \
 | sed 's/;$//' \
 | xargs -r -I{} nft delete rule inet filter input handle {}

# 3. Criar regras definitivas
nft add rule inet filter input icmp type timestamp-request drop
nft add rule inet filter input icmp type timestamp-reply drop

# 4. Persistência
nft list ruleset >/etc/nftables.conf