#!/usr/bin/env bash
echo "[111 - 118] Parâmetros de rede (IPv4 - sysctl)"

check_sysctl() {
  local id="$1"
  local param="$2"
  local expected="$3"
  local valor
  valor=$(sysctl -n "$param" 2>/dev/null)

  if [[ "$valor" == "$expected" ]]; then
    echo "[$id] ✅ APROVADO - $param = $valor"
  else
    echo "[$id] ⚠️ REPROVADO - $param = $valor (esperado: $expected)"
  fi
}

check_sysctl 111 net.ipv4.ip_forward 0
check_sysctl 112 net.ipv4.conf.all.send_redirects 0
check_sysctl 113 net.ipv4.icmp_ignore_bogus_error_responses 1
check_sysctl 114 net.ipv4.icmp_echo_ignore_broadcasts 1
check_sysctl 115 net.ipv4.conf.all.accept_redirects 0
check_sysctl 116 net.ipv4.conf.all.secure_redirects 0
check_sysctl 117 net.ipv4.conf.all.rp_filter 1
check_sysctl 118 net.ipv4.conf.all.accept_source_route 0

echo -e "\n[ICMP] Verifique se timestamp-request está configurado para drop"
( nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-request[[:space:]]+drop' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[ICMP] Verifique se timestamp-reply está configurado para drop"
( nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-reply[[:space:]]+drop' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
