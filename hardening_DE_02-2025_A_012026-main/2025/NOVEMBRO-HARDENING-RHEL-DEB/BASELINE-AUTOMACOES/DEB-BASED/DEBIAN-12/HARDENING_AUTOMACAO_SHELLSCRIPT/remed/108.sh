#!/usr/bin/env bash
# remediate_network_and_modules.sh
TS="$(date +%F_%H%M%S)"

OUT_BLACKLIST="/etc/modprobe.d/99-harden-blacklist.conf"
OUT_SYSCTL="/etc/sysctl.d/99-harden-net.conf"

# ----------------------------
echo -e "\n[108] Remediação - Desabilitar IPv6"
SYSCTL_FILE="/etc/sysctl.d/99-disable-ipv6.conf"
[ -f "$SYSCTL_FILE" ] && cp "$SYSCTL_FILE" "${SYSCTL_FILE}.bak_${TS}" && echo "❗ Backup criado em ${SYSCTL_FILE}.bak_${TS}"
cat > "$SYSCTL_FILE" <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
EOF
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
echo "✅ IPv6 desabilitado (all)"

# ----------------------------
echo -e "\n[109-110] Remediação: desabilitar bluetooth e interfaces wireless"
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
  echo "✅ rfkill block applied (bluetooth/wlan)"
else
  echo "⚠️ rfkill ausente — não foi possível bloquear via rfkill"
fi

# ----------------------------
echo -e "\n[111-114] Remediação: blacklist de módulos dccp, tipc, rds, sctp"
[ -f "$OUT_BLACKLIST" ] && cp -a "$OUT_BLACKLIST" "${OUT_BLACKLIST}.bak_${TS}" && echo "✅ backup ${OUT_BLACKLIST}.bak_${TS}"
for m in dccp tipc rds sctp; do
  if ! grep -Pq "^\s*(install\s+$m\b|blacklist\s+$m\b)" "$OUT_BLACKLIST" 2>/dev/null; then
    printf "install %s /bin/true\nblacklist %s\n" "$m" "$m" >> "$OUT_BLACKLIST"
  fi
  if lsmod | grep -q "^${m}\b"; then
    modprobe -r "$m" 2>/dev/null || echo "⚠️ não foi possível remover módulo carregado: $m"
  fi
done
echo "✅ Blacklist aplicada em $OUT_BLACKLIST (reboot pode ser necessário)"

# ----------------------------
echo -e "\n[115-124] Remediação: aplicar sysctl de rede"
[ -f "$OUT_SYSCTL" ] && cp -a "$OUT_SYSCTL" "${OUT_SYSCTL}.bak_${TS}" && echo "✅ backup ${OUT_SYSCTL}.bak_${TS}"

cat > "$OUT_SYSCTL" <<'EOF'
# Harden network settings (HITSS subset)
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_syncookies = 1
EOF

sysctl --system >/dev/null 2>&1 && echo "✅ sysctl applied (all)" || echo "⚠️ Falha ao aplicar sysctl --system"

# ----------------------------
echo -e "\n[125] Remediação - IPv6 Router Advertisements"
FILE="/etc/sysctl.d/60-IPv6-accept_ra.conf"
[ -f "$FILE" ] && cp "$FILE" "${FILE}.bak_${TS}" && echo "❗ Backup criado em ${FILE}.bak_${TS}"
cat > "$FILE" <<EOF
net.ipv6.conf.all.accept_ra = 0
EOF
sysctl -w net.ipv6.conf.all.accept_ra=0 >/dev/null 2>&1
echo "✅ IPv6 Router Advertisements desabilitados (all)"

echo "[ICMP] Garantir DROP para timestamp-request e timestamp-reply no /etc/nftables.conf"
# 1. Se não existir, cria estrutura básica
if ! grep -q 'table inet filter' /etc/nftables.conf; then
    echo 'table inet filter { chain input { type filter hook input priority 0; } }' >> /etc/nftables.conf
fi
# 2. Remove regras antigas (timestamp-request/reply)
sed -i '/icmp[[:space:]]\+type[[:space:]]\+timestamp-\(request\|reply\)[[:space:]]\+drop/d' /etc/nftables.conf
# 3. Adiciona regras definitivas
grep -q 'chain input' /etc/nftables.conf && \
echo '    icmp type timestamp-request drop' >> /etc/nftables.conf && \
echo '    icmp type timestamp-reply drop' >> /etc/nftables.conf
echo "✅ Regras adicionadas ao /etc/nftables.conf (serão aplicadas quando nftables iniciar)"