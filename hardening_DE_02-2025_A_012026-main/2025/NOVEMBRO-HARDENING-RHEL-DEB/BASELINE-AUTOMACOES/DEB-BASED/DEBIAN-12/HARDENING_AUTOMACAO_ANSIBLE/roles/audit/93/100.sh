#!/usr/bin/env bash
# Auditoria - Controles 100 a 106 (Cron)
echo -e "\n[100] Verifique se as permissões de /etc/crontab estão configuradas"
stat -Lc "%a %U %G" /etc/crontab 2>/dev/null | grep -Eq '^600 root root$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[101] Verifique se as permissões de /etc/cron.hourly estão configuradas"
stat -Lc "%a %U %G" /etc/cron.hourly 2>/dev/null | grep -Eq '^700 root root$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[102] Verifique se as permissões de /etc/cron.daily estão configuradas"
stat -Lc "%a %U %G" /etc/cron.daily 2>/dev/null | grep -Eq '^700 root root$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[103] Verifique se as permissões de /etc/cron.weekly estão configuradas"
stat -Lc "%a %U %G" /etc/cron.weekly 2>/dev/null | grep -Eq '^700 root root$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[104] Verifique se as permissões de /etc/cron.monthly estão configuradas"
stat -Lc "%a %U %G" /etc/cron.monthly 2>/dev/null | grep -Eq '^700 root root$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[105] Verifique se as permissões de /etc/cron.d estão configuradas"
stat -Lc "%a %U %G" /etc/cron.d 2>/dev/null | grep -Eq '^700 root root$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[106] Verifique se o crontab é restrito a usuários autorizados (/etc/cron.allow)"
stat -Lc "%a %U %G" /etc/cron.allow 2>/dev/null | grep -Eq '^640 root (root|crontab)$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
