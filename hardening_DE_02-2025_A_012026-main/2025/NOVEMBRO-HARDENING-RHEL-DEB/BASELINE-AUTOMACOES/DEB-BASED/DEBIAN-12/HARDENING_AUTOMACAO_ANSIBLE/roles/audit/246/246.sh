#!/usr/bin/env bash
# [246–253] Auditoria - Configurações do auditd

echo -e "\n[246] Verifique se pacotes auditd estão instalados"
(dpkg -s auditd &>/dev/null && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[247] Verifique se o serviço auditd está habilitado e ativo"
(systemctl is-enabled auditd &>/dev/null && systemctl is-active auditd &>/dev/null && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[248] Verifique se audit=1 está no GRUB (auditar processos antes do auditd)"
(grep -Po 'GRUB_CMDLINE_LINUX_DEFAULT=.*\baudit=1\b' /etc/default/grub 2>/dev/null | grep -q . && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[249] Verifique se audit_backlog_limit está configurado (>=8192)"
(grep -Po 'GRUB_CMDLINE_LINUX_DEFAULT=.*\baudit_backlog_limit=\d+\b' /etc/default/grub 2>/dev/null | grep -q '8192' && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[250] Verifique se max_log_file está configurado"
([ -f /etc/audit/auditd.conf ] && grep -Eq '^\s*max_log_file\s*=\s*[0-9]+' /etc/audit/auditd.conf && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[251] Verifique se max_log_file_action não é rotate"
([ -f /etc/audit/auditd.conf ] && grep -Eq '^\s*max_log_file_action\s*=\s*keep_logs' /etc/audit/auditd.conf && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[252] Verifique se disk_full_action está configurado para halt ou single"
([ -f /etc/audit/auditd.conf ] && grep -Eq '^\s*disk_full_action\s*=\s*(halt|single)' /etc/audit/auditd.conf && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[253] Verifique se admin_space_left_action está configurado para syslog"
([ -f /etc/audit/auditd.conf ] && grep -Eq '^\s*admin_space_left_action\s*=\s*syslog' /etc/audit/auditd.conf && echo "✅ APROVADO") || echo "⚠️ REPROVADO"