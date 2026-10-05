#!/usr/bin/env bash
set -euo pipefail

#echo -e "\n[165–166] Instalar e habilitar auditd"
#if ! rpm -q audit >/dev/null 2>&1; then
#  yum -y install audit >/dev/null 2>&1
#fi
#systemctl enable auditd >/dev/null 2>&1 || true
#systemctl start  auditd >/dev/null 2>&1 || true

echo -e "\n[167] Ajustar max_log_file = 50"

CONF="/etc/audit/auditd.conf"
[ -f "$CONF" ] && cp -a "$CONF" "$CONF.bkp_$(date +%Y%m%d_%H%M%S)"

if grep -Eq '^[[:space:]]*max_log_file' "$CONF"; then
  sed -ri 's|^[[:space:]]*max_log_file.*|max_log_file = 50|' "$CONF"
else
  echo "max_log_file = 50" >> "$CONF"
fi

systemctl restart auditd >/dev/null 2>&1 || true
echo "[OK] max_log_file ajustado"
