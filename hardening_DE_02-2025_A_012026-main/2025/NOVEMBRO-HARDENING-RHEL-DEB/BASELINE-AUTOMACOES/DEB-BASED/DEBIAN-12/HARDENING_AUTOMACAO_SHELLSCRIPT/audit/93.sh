#!/usr/bin/env bash
# Auditoria - Controles 93 a 106 (Time sync & Cron)

echo -e "\n[93] Verifique se apenas um daemon de sincronização de tempo está em uso"
( (systemctl is-active --quiet systemd-timesyncd.service && ! systemctl is-active --quiet chrony.service) || (! systemctl is-active --quiet systemd-timesyncd.service && systemctl is-active --quiet chrony.service) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[94] Verifique se systemd-timesyncd está configurado com servidor(es) NTP autorizados"
if systemctl is-active --quiet systemd-timesyncd.service; then
  ( grep -Piq '^\s*NTP\s*=' /etc/systemd/timesyncd.conf 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
else
  # se chrony está ativo, considerar ok
  systemctl is-active --quiet chrony.service && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
fi

echo -e "\n[95] Verifique se systemd-timesyncd está habilitado e em execução"
if systemctl is-active --quiet systemd-timesyncd.service; then
  ( systemctl is-enabled --quiet systemd-timesyncd.service && systemctl is-active --quiet systemd-timesyncd.service ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
else
  systemctl is-active --quiet chrony.service && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
fi

echo -e "\n[96] Verifique se chrony está configurado com servidor(es) autorizados"
( systemctl is-active --quiet chrony.service && grep -Piq '^\s*(server|pool)\s+' /etc/chrony/chrony.conf 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[97] Verifique se o chronyd está rodando como usuário _chrony"
pgrep -u _chrony -x chronyd >/dev/null 2>&1 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[98] Verifique se chrony está habilitado e em execução"
( systemctl is-enabled --quiet chrony.service 2>/dev/null && systemctl is-active --quiet chrony.service 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[99] Verifique se o daemon cron está habilitado e ativo"
( systemctl is-enabled --quiet cron.service 2>/dev/null && systemctl is-active --quiet cron.service ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"