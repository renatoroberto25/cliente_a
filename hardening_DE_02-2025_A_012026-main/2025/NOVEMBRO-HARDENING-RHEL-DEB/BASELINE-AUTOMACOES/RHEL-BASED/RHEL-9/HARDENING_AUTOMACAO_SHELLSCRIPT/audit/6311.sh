#!/usr/bin/env bash
echo "237 Ensure  packages are installed"

if rpm -q audit audit-libs &>/dev/null; then
echo "✅ [APROVADO]: audit e audit-libs estão instalados"
else
echo "⚠️[REPROVADO]: audit e audit-libs NÃO estão instalados"
fi

echo "238 Ensure auditing for processes that start prior to  is enabled"
if grep -Pq -- '^\h*GRUB_CMDLINE_LINUX=\"([^#\n\r]+\h+)?audit=1\b' /etc/default/grub; then
echo "✅ [APROVADO]: Opção audit=1 encontrada na linha GRUB_CMDLINE_LINUX em /etc/default/grub"
else
echo "⚠️[REPROVADO]: Opção audit=1 NÃO encontrada na linha GRUB_CMDLINE_LINUX em /etc/default/grub"
fi

echo "239 Ensure audit_backlog_limit is sufficient"
if grep -Psoi -- '^\h*GRUB_CMDLINE_LINUX=\"([^#\n\r]+\h+)?\baudit_backlog_limit=\d+\b' /etc/default/grub; then
echo "✅ [APROVADO]: Opção baudit_backlog_limit encontrada."
else
echo "⚠️[REPROVADO]: Opção baudit_backlog_limit NÃO encontrada."
fi

echo "240 Ensure  service is enabled and active"
auditd_enabled=$(systemctl is-enabled auditd | grep '^enabled' 2>/dev/null)
auditd_active=$(systemctl is-active auditd.service 2>/dev/null)

if [[ "$auditd_enabled" == "enabled" && "$auditd_active" == "active" ]]; then
echo "✅ [APROVADO]: auditd.service está habilitado e ativo"
else
echo "⚠️[REPROVADO]: auditd.service NÃO está habilitado ou ativo"
echo "Status: enabled=$auditd_enabled, active=$auditd_active"
fi