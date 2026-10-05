#!/usr/bin/env bash
# [35-38] Remediação HITSS - Core dumps, NX, ASLR, Prelink (Servidores baseados em RHEL 7)
# Versão refinada, mesma lógica do audit.
set -euo pipefail

# [35] Restringir core dumps
echo -e "\n[35] Restringir core dumps"
limits_conf="/etc/security/limits.conf"
sysctl_conf="/etc/sysctl.conf"
[ -f "$limits_conf" ] && cp -a "$limits_conf" "$limits_conf.bak.$(date +%F_%H%M%S)"
[ -f "$sysctl_conf" ] && cp -a "$sysctl_conf" "$sysctl_conf.bak.$(date +%F_%H%M%S)"

grep -q '^\*\s\+hard\s\+core\s\+0' "$limits_conf" 2>/dev/null || echo "* hard core 0" >> "$limits_conf"

sed -i '/^\s*fs\.suid_dumpable\s*=/d' "$sysctl_conf"
echo "fs.suid_dumpable = 0" >> "$sysctl_conf"
sysctl -w fs.suid_dumpable=0 >/dev/null

# [36] NX/XD é hardware-level — só alerta se desativado
echo -e "\n[36] NX/XD depende de BIOS/CPU - verificar manualmente se não ativo"
dmesg | grep -qi 'NX (Execute Disable) protection: active' || echo "⚠️ Ative NX/XD no BIOS se disponível"

# [37] Ativar ASLR
echo -e "\n[37] Ativar ASLR"
sed -i '/^\s*kernel\.randomize_va_space\s*=/d' "$sysctl_conf"
echo "kernel.randomize_va_space = 2" >> "$sysctl_conf"
sysctl -w kernel.randomize_va_space=2 >/dev/null

# [38] Remover prelink se presente
echo -e "\n[38] Remover pacote prelink (se instalado)"
rpm -q prelink &>/dev/null && yum remove -y prelink || true

chmod 0644 "$limits_conf" "$sysctl_conf" 2>/dev/null || true
