#!/usr/bin/env bash
echo -e "\n[221] Verifique se contas de sistema não possuem shell de login"
awk -F: '($3<1000 && $7 !~ /(nologin|false)$/ && $1!~/^(root|sync|shutdown|halt)$/){exit 1}' /etc/passwd \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[222] Verifique se contas sem shell válido estão bloqueadas"
awk -F: '($7~/nologin$|false$/ && $1!="root"){print $1}' /etc/passwd | while read -r user; do
  status="$(passwd -S "$user" 2>/dev/null | awk '{print $2}')"
  [ "$status" = "L" ] || exit 1
done && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[223] Verifique se /etc/shells não contém /nologin"
grep -Eq '^[^#].*/nologin' /etc/shells && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[224] Verifique se TMOUT <= 900 está configurado como readonly e exportado"
grep -Pq '^\s*TMOUT=(900|[1-8][0-9]{2}|[1-9][0-9]?)\b' /etc/profile /etc/bashrc /etc/profile.d/*.sh 2>/dev/null \
  && grep -Pq '^\s*readonly\s+TMOUT\b' /etc/profile /etc/bashrc /etc/profile.d/*.sh 2>/dev/null \
  && grep -Pq '^\s*export\s+TMOUT\b' /etc/profile /etc/bashrc /etc/profile.d/*.sh 2>/dev/null \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[225] Verifique se umask padrão está configurada (027)"
grep -Pq '^\s*umask\s+0?27\b' /etc/profile /etc/bashrc /etc/login.defs /etc/profile.d/*.sh 2>/dev/null \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"