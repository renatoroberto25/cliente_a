#!/usr/bin/env bash
echo "[260-262] AIDE - Integridade e Proteção Criptográfica"

echo -e "\n[260] Verifique se o AIDE está instalado"
(rpm -q aide &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[261] Verifique se o AIDE possui agendamento de verificação"
(egrep -R "(aide(\.wrapper)? .*(--check|--update|\$AIDEARGS))" /etc/cron.* /etc/crontab /var/spool/cron 2>/dev/null \
 || (systemctl is-enabled aidecheck.timer &>/dev/null && systemctl is-active aidecheck.timer &>/dev/null)) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"


echo -e "\n[262] Verifique se o AIDE está configurado para proteger ferramentas de auditoria com mecanismos criptográficos"
grep -Ps -- '(\/sbin\/(audit|au)\H*\b)' /etc/aide.conf /etc/aide.conf.d/*.conf 2>/dev/null \
 | grep -q 'sha512' \
 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"