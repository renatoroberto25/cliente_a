#!/usr/bin/env bash

echo -e "\n[155] Verifique permissões de /etc/ssh/sshd_config e arquivos .conf"
(stat -c "%a %U %G" /etc/ssh/sshd_config 2>/dev/null | grep -Eq '^60[04]\s+root\s+root$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[156] Verifique permissões das chaves privadas SSH"
(find /etc/ssh -type f -name "ssh_host_*_key" ! -perm 600 | grep -q .) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[157] Verifique permissões das chaves públicas SSH"
(find /etc/ssh -type f -name "ssh_host_*_key.pub" ! -perm 644 | grep -q .) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[158] Verifique se o acesso ao sshd está configurado (AllowUsers/Groups, DenyUsers/Groups)"
grep -Eq '^\s*(AllowUsers|AllowGroups|DenyUsers|DenyGroups)\s+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[159] Verifique se o Banner do SSH está configurado"
grep -Eq '^Banner\s+/.+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"