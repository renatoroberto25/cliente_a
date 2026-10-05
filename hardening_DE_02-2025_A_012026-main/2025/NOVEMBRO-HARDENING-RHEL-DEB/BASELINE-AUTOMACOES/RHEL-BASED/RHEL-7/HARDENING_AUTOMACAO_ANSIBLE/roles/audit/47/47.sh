#!/usr/bin/env bash
# [47–52] Auditoria HITSS - Banners e permissões (Servidores baseados em RHEL 7)
set -euo pipefail

echo -e "\n[47] Verifique se o banner /etc/motd está configurado corretamente"
grep -Eq "Authorized|access|unauthorized|prohibited" /etc/motd 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[48] Verifique se o banner local (/etc/issue) está configurado corretamente"
grep -Eq "Authorized|access|unauthorized|prohibited" /etc/issue 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[49] Verifique se o banner remoto (/etc/issue.net) está configurado corretamente"
grep -Eq "Authorized|access|unauthorized|prohibited" /etc/issue.net 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[50] Verifique se as permissões de /etc/motd estão corretas"
[ -f /etc/motd ] && stat -c "%a %U %G" /etc/motd | grep -qE "^644 root root$" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[51] Verifique se as permissões de /etc/issue estão corretas"
[ -f /etc/issue ] && stat -c "%a %U %G" /etc/issue | grep -qE "^644 root root$" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[52] Verifique se as permissões de /etc/issue.net estão corretas"
[ -f /etc/issue.net ] && stat -c "%a %U %G" /etc/issue.net | grep -qE "^644 root root$" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


echo -e "\n[56] Verifique se o XDMCP está desabilitado"
grep -Eiq '^\s*(Enable|enabled)\s*=\s*true' /etc/gdm/custom.conf /etc/lightdm/lightdm.conf 2>/dev/null && \
  echo "⚠️ REPROVADO" || echo "✅ APROVADO"