#!/usr/bin/env bash
echo "[134–140] Remediação automática segura - Auditd base e inicialização"

# 134 - Ensure auditd is installed
echo "[134] Garantindo que o auditd esteja instalado"
if ! rpm -q audit &>/dev/null; then
  dnf install -y audit audit-libs && echo "✅ auditd instalado com sucesso"
else
  echo "✅ auditd já instalado"
fi

# 135 - Ensure auditd service is enabled and running
echo "[135] Garantindo que o auditd esteja habilitado e em execução"
if ! systemctl is-enabled auditd &>/dev/null || ! systemctl is-active auditd &>/dev/null; then
  systemctl enable --now auditd && echo "✅ auditd habilitado e iniciado"
else
  echo "✅ auditd já estava ativo"
fi

# 136 - Ensure auditing before auditd starts
echo "[136] Configuração de auditoria antes do auditd (GRUB)"
if grep -q "audit=1" /etc/default/grub /etc/grub2.cfg 2>/dev/null; then
  echo "✅ Parâmetro audit=1 já configurado"
else
  echo "⚠️ Requer ajuste manual — adicione 'audit=1' em GRUB_CMDLINE_LINUX e regenere com grub2-mkconfig -o /boot/grub2/grub.cfg"
fi

# 137 - Ensure audit log storage size is configured
echo "[137] Configurando tamanho máximo dos logs de auditoria"
if grep -q "^max_log_file" /etc/audit/auditd.conf 2>/dev/null; then
  sed -i 's/^max_log_file.*/max_log_file = 8/' /etc/audit/auditd.conf
else
  echo "max_log_file = 8" >> /etc/audit/auditd.conf
fi
echo "✅ max_log_file configurado (8 MB padrão)"

# 138 - Ensure audit logs are not automatically deleted
echo "[138] Garantindo que os logs do auditd não sejam excluídos automaticamente"
if grep -q "^max_log_file_action" /etc/audit/auditd.conf 2>/dev/null; then
  sed -i 's/^max_log_file_action.*/max_log_file_action = keep_logs/' /etc/audit/auditd.conf
else
  echo "max_log_file_action = keep_logs" >> /etc/audit/auditd.conf
fi
echo "✅ max_log_file_action ajustado para keep_logs"

# 139 - Ensure system disabled when logs full
echo "[139] Ação ao encher logs (manual)"
if grep -Eq "space_left_action *= *(email|halt)" /etc/audit/auditd.conf 2>/dev/null; then
  echo "✅ Parâmetro configurado"
else
  echo "⚠️ Manual — defina em /etc/audit/auditd.conf:"
  echo "    space_left_action = email"
  echo "    admin_space_left_action = halt"
fi

# 140 - Ensure audit_backlog_limit is sufficient
echo "[140] Verifique se o audit_backlog_limit está configurado"
if grep -q "audit_backlog_limit" /etc/default/grub /etc/grub2.cfg 2>/dev/null; then
  echo "✅ audit_backlog_limit já configurado"
else
  echo "⚠️ Requer ajuste manual — adicione 'audit_backlog_limit=8192' em GRUB_CMDLINE_LINUX e regenere com grub2-mkconfig -o /boot/grub2/grub.cfg"
fi