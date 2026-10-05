#!/usr/bin/env bash
echo -e "\n[215] Verifique se apenas root possui UID 0"
awk -F: '($3==0){print $1}' /etc/passwd | grep -qx "root" \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[216] Verifique se apenas root possui GID 0 (exceto sync,shutdown,halt,operator)"
awk -F: '($4==0 && $1!~/^(root|sync|shutdown|halt|operator)$/){exit 1}' /etc/passwd \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[217] Verifique se apenas o grupo root possui GID 0"
awk -F: '($3==0 && $1!="root"){exit 1}' /etc/group \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[218] Verifique se a conta root possui senha definida ou está bloqueada"
passwd -S root 2>/dev/null | awk '{if($2~/^(P|L)$/) exit 0; else exit 1}' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[219] Verifique a integridade do PATH do root"
root_path="$(sudo -Hiu root env | grep '^PATH=' | cut -d= -f2)"
echo "$root_path" | grep -Eq '(^|:)(:|\.(:|$))' && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[220] Verifique se umask do root está configurada (027 ou 077)"
grep -Pi '^\s*umask\s+(027|077)\b' /root/.bashrc /root/.bash_profile 2>/dev/null | grep -q . \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"