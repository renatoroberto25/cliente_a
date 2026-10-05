#!/usr/bin/env bash
echo "241 Ensure audit log storage size is configured"
if grep -Pq -- '^\h*max_log_file\h*=\h*\d+\b' /etc/audit/auditd.conf; then
echo "✅ [APROVADO]: max_log_file está configurado em /etc/audit/auditd.conf"
else
echo "⚠️[REPROVADO]: max_log_file NÃO está configurado corretamente em /etc/audit/auditd.conf"
fi

echo "242 Ensure audit logs are not automatically deleted"
if grep -Pq -- '^\h*max_log_file_action\h*=\h*(?!(ROTATE|rotate)\b)' /etc/audit/auditd.conf; then
echo "✅ [APROVADO]: max_log_file_action NÃO está configurado para ROTATE"
else
echo "⚠️[REPROVADO]: max_log_file_action está configurado como ROTATE ou não foi encontrado"
fi

echo "243 Ensure system is disabled when audit logs are full"
if grep -Pq -- '^\h*disk_full_action\h*=\h*(halt|single)\b' /etc/audit/auditd.conf; then
echo "✅ [APROVADO]: disk_full_action está configurado como halt ou single"
else
echo "⚠️[REPROVADO]: disk_full_action NÃO está configurado como halt ou single"
fi

echo "244 Ensure system warns when audit logs are low on space"
if grep -Pq -- '^\h*space_left_action\h*=\h*(email|exec|single|halt)\b' /etc/audit/auditd.conf; then
echo "✅ [APROVADO]: space_left_action está configurado corretamente"
else
echo "⚠️[REPROVADO]: space_left_action NÃO está configurado corretamente"
fi