#!/usr/bin/env bash

echo -e "\n[195] Verificar existência de arquivos órfãos (UID/GID sem dono)"
( find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[196] Verificar world-writable fora de áreas permitidas"
( find / -xdev -not -path "/tmp/*" -not -path "/var/tmp/*" -not -path "/dev/shm/*" -perm -0002 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[197] Verificar arquivos/diretórios sem owner ou group"
( find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[198] Verificar binários SUID/SGID"
( find / -xdev \( -perm -4000 -o -perm -2000 \) 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[199] Verificar se usuários possuem diretório home válido (Debian: excluir nobody)"
( awk -F: '$3>=1000 && $1!="nobody" {print $6}' /etc/passwd | while read h; do [ -d "$h" ] || exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[200] Verificar ownership das homes dos usuários (Debian: excluir nobody)"
( awk -F: '$3>=1000 && $1!="nobody" {print $1,$6}' /etc/passwd | while read u h; do [ -d "$h" ] && [ "$(stat -Lc %U "$h")" = "$u" ] || exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[201] Verificar permissões das homes (<=750)"
( awk -F: '$3>=1000 && $1!="nobody"{print $6}' /etc/passwd | while read h; do [ -d "$h" ] && [ "$(stat -Lc %a "$h")" -le 750 ] || exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[202] Verificar dotfiles inseguros nas homes"
( awk -F: '$3>=1000 && $1!="nobody"{print $6}' /etc/passwd | while read h; do find "$h" -maxdepth 1 -type f -name ".*" -perm /022 2>/dev/null | grep -q . && exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[203] Verificar arquivos .forward/.netrc/.rhosts nas homes"
( awk -F: '$3>=1000 && $1!="nobody"{print $6}' /etc/passwd | while read h; do [ -e "$h/.forward" ] || [ -e "$h/.netrc" ] || [ -e "$h/.rhosts" ] && exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
