#!/usr/bin/env bash

echo -e "\n[182] AIDE instalado e inicializado (Debian: dpkg)"
( dpkg -s aide &>/dev/null && ls /var/lib/aide/*.db* &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[183] Verificação de integridade agendada (cron ou timer)"
( grep -Ersq 'aide(\.wrapper)? .*(--check|--update|\$AIDEARGS)' /etc/cron.* /etc/crontab /var/spool/cron 2>/dev/null \
  || systemctl list-timers --all 2>/dev/null | grep -Ei 'aide' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[184] Proteção dos binários de auditoria (Debian: /usr/sbin)"
( stat -Lc "%a %U %G" /usr/sbin/auditctl /usr/sbin/aureport /usr/sbin/ausearch /usr/sbin/autrace /usr/sbin/auditd /usr/sbin/augenrules 2>/dev/null \
  | awk '{if($1+0>750 || $2!="root" || $3!="root") exit 1}' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE
