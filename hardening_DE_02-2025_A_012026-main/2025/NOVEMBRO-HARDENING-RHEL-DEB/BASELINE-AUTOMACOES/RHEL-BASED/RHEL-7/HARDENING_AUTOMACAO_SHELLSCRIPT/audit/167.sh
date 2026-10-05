#!/usr/bin/env bash
echo "[167–175] Verificações de configuração do agendador Cron e At"

# 167 - Ensure cron daemon is enabled and running
echo "[167] Verifique se o serviço cron está habilitado e em execução"
systemctl is-enabled crond &>/dev/null && systemctl is-active crond &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 168 - Ensure permissions on /etc/crontab are configured
echo "[168] Verifique permissões de /etc/crontab"
[ -f /etc/crontab ] && stat -c "%a" /etc/crontab | grep -q "^600$" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 169 - Ensure permissions on /etc/cron.hourly are configured
echo "[169] Verifique permissões de /etc/cron.hourly"
[ -d /etc/cron.hourly ] && stat -c "%a" /etc/cron.hourly | grep -q "^700$" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 170 - Ensure permissions on /etc/cron.daily are configured
echo "[170] Verifique permissões de /etc/cron.daily"
[ -d /etc/cron.daily ] && stat -c "%a" /etc/cron.daily | grep -q "^700$" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 171 - Ensure permissions on /etc/cron.weekly are configured
echo "[171] Verifique permissões de /etc/cron.weekly"
[ -d /etc/cron.weekly ] && stat -c "%a" /etc/cron.weekly | grep -q "^700$" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 172 - Ensure permissions on /etc/cron.monthly are configured
echo "[172] Verifique permissões de /etc/cron.monthly"
[ -d /etc/cron.monthly ] && stat -c "%a" /etc/cron.monthly | grep -q "^700$" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 173 - Ensure permissions on /etc/cron.d are configured
echo "[173] Verifique permissões de /etc/cron.d"
[ -d /etc/cron.d ] && stat -c "%a" /etc/cron.d | grep -q "^700$" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 174 - Ensure cron is restricted to authorized users
echo "[174] Verifique restrição de uso do cron"
[ -f /etc/cron.allow ] && [ ! -f /etc/cron.deny ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 175 - Ensure at is restricted to authorized users
echo "[175] Verifique restrição de uso do at"
[ -f /etc/at.allow ] && [ ! -f /etc/at.deny ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"