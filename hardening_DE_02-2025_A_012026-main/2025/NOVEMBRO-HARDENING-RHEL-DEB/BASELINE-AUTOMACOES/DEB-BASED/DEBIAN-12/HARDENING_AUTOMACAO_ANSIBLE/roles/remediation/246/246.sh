#!/usr/bin/env bash
# remediate_auditd_246-253.sh
# Remediação HITSS Debian 12 - Auditd (246–253)
set -u
TS="$(date +%Y%m%d_%H%M%S)"
AUDIT_CONF="/etc/audit/auditd.conf"
GRUB_DEF="/etc/default/grub"

backup_file() { [[ -f "$1" ]] && cp -p "$1" "$1.bak_${TS}" && echo "  Backup criado: $1.bak_${TS}"; }

echo "[246–253] Remediação auditd - início $(date)"

# 246
echo -e "\n[246] Garantindo pacotes auditd instalados"
if ! dpkg -s auditd &>/dev/null; then
  apt-get update -qq && apt-get install -y auditd audispd-plugins && echo "  ✅ Instalado"
else
  echo "  ✅ Já instalado"
fi

# 247
echo -e "\n[247] Garantindo auditd habilitado e ativo"
(systemctl is-enabled auditd &>/dev/null && systemctl is-active auditd &>/dev/null) || systemctl enable --now auditd
echo "  ✅ auditd habilitado e ativo"

# 248
echo -e "\n[248] Garantindo audit=1 no GRUB"
if ! grep -Pq '\baudit=1\b' "$GRUB_DEF"; then
  backup_file "$GRUB_DEF"
  sed -ri 's/^(GRUB_CMDLINE_LINUX_DEFAULT=".*)"/\1 audit=1"/' "$GRUB_DEF"
  echo "  ⚠️ Adicionado audit=1 (executar grub-mkconfig e reboot)"
else
  echo "  ✅ Já configurado"
fi

# 249
echo -e "\n[249] Garantindo audit_backlog_limit>=8192 no GRUB"
if grep -Pq 'audit_backlog_limit=\d+' "$GRUB_DEF"; then
  CUR=$(grep -Po 'audit_backlog_limit=\K\d+' "$GRUB_DEF" | tail -1 || echo 0)
  if [ "$CUR" -lt 8192 ]; then
    backup_file "$GRUB_DEF"
    sed -ri "s/audit_backlog_limit=$CUR/audit_backlog_limit=8192/" "$GRUB_DEF"
    echo "  ⚠️ Atualizado para 8192 (grub-mkconfig e reboot)"
  else
    echo "  ✅ Já >=8192"
  fi
else
  backup_file "$GRUB_DEF"
  sed -ri 's/^(GRUB_CMDLINE_LINUX_DEFAULT=".*)"/\1 audit_backlog_limit=8192"/' "$GRUB_DEF"
  echo "  ⚠️ Adicionado (grub-mkconfig e reboot)"
fi

# garantir arquivo
backup_file "$AUDIT_CONF"; touch "$AUDIT_CONF"

# 250
echo -e "\n[250] Garantindo max_log_file >= 100"
if grep -Pq '^\s*max_log_file\s*=' "$AUDIT_CONF"; then
  sed -ri 's/^\s*max_log_file\s*=.*/max_log_file = 100/' "$AUDIT_CONF"
else
  echo "max_log_file = 100" >> "$AUDIT_CONF"
fi

# 251
echo -e "\n[251] Garantindo max_log_file_action = keep_logs"
if grep -Pq '^\s*max_log_file_action\s*=' "$AUDIT_CONF"; then
  sed -ri 's/^\s*max_log_file_action\s*=.*/max_log_file_action = keep_logs/' "$AUDIT_CONF"
else
  echo "max_log_file_action = keep_logs" >> "$AUDIT_CONF"
fi

# 252
echo -e "\n[252] Garantindo disk_full_action = halt"
if grep -Pq '^\s*disk_full_action\s*=' "$AUDIT_CONF"; then
  sed -ri 's/^\s*disk_full_action\s*=.*/disk_full_action = halt/' "$AUDIT_CONF"
else
  echo "disk_full_action = halt" >> "$AUDIT_CONF"
fi

# 253
echo -e "\n[253] Garantindo admin_space_left_action = syslog"
if grep -Pq '^\s*admin_space_left_action\s*=' "$AUDIT_CONF"; then
  sed -ri 's/^\s*admin_space_left_action\s*=.*/admin_space_left_action = syslog/' "$AUDIT_CONF"
else
  echo "admin_space_left_action = syslog" >> "$AUDIT_CONF"
fi

systemctl reload auditd 2>/dev/null || systemctl restart auditd
echo -e "\n⚠️ Execute: grub-mkconfig -o /boot/grub/grub.cfg && reboot para aplicar parâmetros do GRUB"
echo -e "\n Quando você usa reboot, o kernel reaproveita parte do estado do sistema e às vezes não reprocesa o grub.cfg inteiro, então os novos parâmetros (audit=1, audit_backlog_limit=8192) podem não carregar."
echo -e "\n Já quando você faz um desligar completo (poweroff / shutdown -h now) e liga de novo, o firmware/BIOS faz POST, o bootloader roda do zero, e aí o GRUB lê novamente o /boot/grub/grub.cfg com as opções atualizadas."
echo -e "\n systemctl --force --force poweroff ou echo b > /proc/sysrq-trigger - pra forçar o reboot a se comportar como desligar+ligar."