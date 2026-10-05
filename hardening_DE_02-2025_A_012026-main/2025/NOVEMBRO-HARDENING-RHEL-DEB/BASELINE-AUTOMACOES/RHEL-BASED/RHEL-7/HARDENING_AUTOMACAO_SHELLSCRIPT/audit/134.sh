#!/usr/bin/env bash
echo "[134–140] Verificações básicas do auditd"

echo "[134] Verifique se o auditd está instalado"
rpm -q audit &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[135] Verifique se o auditd está habilitado e em execução"
systemctl is-enabled auditd &>/dev/null && systemctl is-active auditd &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[136] Verifique se a auditoria antes do auditd está habilitada"
grep -q "audit=1" /etc/default/grub /etc/grub2.cfg 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[137] Verifique se o tamanho máximo de log do auditd está configurado"
grep -q "max_log_file" /etc/audit/auditd.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[138] Verifique se os logs do auditd não são automaticamente excluídos"
grep -q "max_log_file_action *= *keep_logs" /etc/audit/auditd.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[139] Verifique se o sistema é desabilitado quando os logs estão cheios"
grep -Eq "space_left_action *= *email|halt" /etc/audit/auditd.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[140] Verifique se o audit_backlog_limit é suficiente"
grep -q "audit_backlog_limit" /etc/default/grub /etc/grub2.cfg 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[PLUS] Verifique se a configuração em disco e em execução estão sincronizadas (augenrules --check)"
(augenrules --check 2>&1 | grep -q "No change") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[PLUS] Acessos negados a arquivos devem ser auditados"
(egrep -iq 'EACCES|EPERM' /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || auditctl -l | egrep -iq 'EACCES|EPERM') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

