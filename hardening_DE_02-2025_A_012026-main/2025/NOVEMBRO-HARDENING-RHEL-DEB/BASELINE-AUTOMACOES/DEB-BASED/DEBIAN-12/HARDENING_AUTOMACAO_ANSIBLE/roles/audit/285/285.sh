#!/usr/bin/env bash
echo -e "\n[285] – Verifique se o AIDE está instalado"
(dpkg -s aide 2>/dev/null | grep -q '^Status: install') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#(command -v aide >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[286] – filesystem integrity regularly checked"
(systemctl is-enabled dailyaidecheck.timer 2>/dev/null | grep -q enabled && \
 systemctl is-active dailyaidecheck.timer 2>/dev/null | grep -q active) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

 echo -e "\n[287] Verifique se o AIDE protege as ferramentas de auditoria com mecanismos criptográficos"
(command -v aide &>/dev/null && grep -Eq "/sbin/(auditctl|auditd|ausearch|aureport|autrace|augenrules).*p\+i\+n\+u\+g\+s\+b\+acl\+xattrs\+sha512" /etc/aide/aide.conf && echo "✅ APROVADO") || echo "⚠️ REPROVADO"