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