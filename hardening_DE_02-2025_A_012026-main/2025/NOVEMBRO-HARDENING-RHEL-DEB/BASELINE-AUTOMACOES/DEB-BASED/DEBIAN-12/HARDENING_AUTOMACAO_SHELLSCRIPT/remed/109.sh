#!/usr/bin/env bash
# remediate_network_and_modules.sh
TS="$(date +%F_%H%M%S)"
OUT_BLACKLIST="/etc/modprobe.d/99-harden-blacklist.conf"
OUT_SYSCTL="/etc/sysctl.d/99-harden-net.conf"

echo -e "\n[109-110] Remediação: desabilitar bluetooth e interfaces wireless (onde aplicável)"
if systemctl list-unit-files | grep -q '^bluetooth.service'; then
  systemctl stop --now bluetooth.service 2>/dev/null || true
  systemctl disable --now bluetooth.service 2>/dev/null || true
  systemctl mask bluetooth.service 2>/dev/null || true
  echo "✅ bluetooth masked/disabled"
else
  echo "✅ bluetooth.service ausente — nada a fazer"
fi
if command -v rfkill >/dev/null 2>&1; then
  rfkill block bluetooth 2>/dev/null || true
  rfkill block wlan 2>/dev/null || true
  echo "✅ rfkill block attempted for bluetooth/wlan"
else
  echo "⚠️ rfkill ausente — não foi possível bloquear via rfkill"
fi

echo -e "\n[111-114] Remediação: blacklist de módulos dccp, tipc, rds, sctp"
[ -f "$OUT_BLACKLIST" ] && cp -a "$OUT_BLACKLIST" "${OUT_BLACKLIST}.bak_${TS}" && echo "✅ backup ${OUT_BLACKLIST}.bak_${TS}"
for m in dccp tipc rds sctp; do
  if ! grep -Pq "^\s*(install\s+$m\b|blacklist\s+$m\b)" "$OUT_BLACKLIST" 2>/dev/null; then
    printf "install %s /bin/true\nblacklist %s\n" "$m" "$m" >> "$OUT_BLACKLIST"
  fi
  # try to remove loaded modules (best-effort)
  if lsmod | grep -q "^${m}\b"; then
    modprobe -r "$m" 2>/dev/null || echo "⚠️ não foi possível remover módulo carregado: $m"
  fi
done
echo "✅ Blacklist aplicada em $OUT_BLACKLIST (recarregue modules ou reboot se necessário)"

echo -e "\n[115-124] Remediação: aplicar sysctl de rede (backup se existir)"
if [ -f "$OUT_SYSCTL" ]; then
  cp -a "$OUT_SYSCTL" "${OUT_SYSCTL}.bak_${TS}" && echo "✅ backup ${OUT_SYSCTL}.bak_${TS}"
fi

cat > "$OUT_SYSCTL" <<'EOF'
# Harden network settings (HITSS/CIS subset)
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_syncookies = 1
# IPv6 RA (apply only if you know IPv6 autoconfig isn't used)
# net.ipv6.conf.all.accept_ra = 0
EOF

if sysctl --system >/dev/null 2>&1; then
  echo "✅ sysctl applied (sysctl --system)"
else
  echo "⚠️ Falha ao aplicar sysctl --system (ver logs)"
fi

echo -e "\nConcluído. Backups: ${OUT_BLACKLIST}.bak_${TS} ${OUT_SYSCTL}.bak_${TS} (se existirem)."