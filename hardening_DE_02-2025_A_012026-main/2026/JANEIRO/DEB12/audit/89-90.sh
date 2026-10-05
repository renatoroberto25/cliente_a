#!/usr/bin/env bash

echo -e "\n[89] Apenas um daemon de time sync"; 
( [ "$(for s in chronyd ntpd systemd-timesyncd; do systemctl is-active --quiet "$s" && echo "$s"; done | wc -l)" -eq 1 ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO" )

echo -e "\n[90] Cron/at seguros e restritos"; 
( stat -Lc '%a %U %G' /etc/cron.allow 2>/dev/null | grep -Eq '^640 root (root|crontab)$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO" )

#MUDAR NO BASELINE
