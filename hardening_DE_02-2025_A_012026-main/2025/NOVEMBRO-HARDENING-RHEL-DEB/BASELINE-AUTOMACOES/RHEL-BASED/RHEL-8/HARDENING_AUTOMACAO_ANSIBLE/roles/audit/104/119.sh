#!/usr/bin/env bash
echo "[119 - 121] Auditoria de log e segurança TCP/IPv6 (sysctl)"

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

check_sysctl 119 net.ipv4.conf.all.log_martians 1
check_sysctl 120 net.ipv4.tcp_syncookies 1
check_sysctl 121 net.ipv6.conf.all.accept_ra 0