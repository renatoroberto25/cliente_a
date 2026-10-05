#!/usr/bin/env bash
echo "[119 - 121] Remediação de parâmetros adicionais de rede (sysctl)"

backup="/etc/sysctl.conf.bak_$(date +%F_%H-%M-%S)"
cp -p /etc/sysctl.conf "$backup" && echo " Backup criado: $backup"

declare -A sysctl_config=(
  [net.ipv4.conf.all.log_martians]=1
  [net.ipv4.tcp_syncookies]=1
  [net.ipv6.conf.all.accept_ra]=0
)

for param in "${!sysctl_config[@]}"; do
  valor="${sysctl_config[$param]}"
  echo "$param = $valor" >> /etc/sysctl.conf
  sysctl -w "$param=$valor" &>/dev/null
  echo "✅ Corrigido: $param = $valor"
done