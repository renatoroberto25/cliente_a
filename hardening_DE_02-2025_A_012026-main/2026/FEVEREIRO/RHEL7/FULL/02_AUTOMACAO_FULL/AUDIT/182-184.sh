#!/usr/bin/env bash
echo -e "\n[182] AIDE instalado e inicializado"
( rpm -q aide &>/dev/null && [ -f /var/lib/aide/aide.db.gz ] ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[183] Verificação de integridade agendada"
( grep -Ersq 'aide(\.wrapper)? .*(--check|--update|\$AIDEARGS)' /etc/cron.* /etc/crontab /var/spool/cron 2>/dev/null || systemctl list-timers --all 2>/dev/null | grep -qi aime ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[184] Proteção dos binários de auditoria"
( stat -Lc "%a %U %G" /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules 2>/dev/null | awk '{if($1+0>750 || $2!="root" || $3!="root") exit 1}' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
