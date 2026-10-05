#!/usr/bin/env bash

echo -e "\n[298] Verifique se não existem arquivos world-writable sem sticky bit"
(find / -xdev \( -type f -perm -0002 -o -type d -perm -0002 ! -perm -1000 \) 2>/dev/null | grep -q . && echo "⚠️ REPROVADO") || echo "✅ APROVADO"

echo -e "\n[299] Verifique se não existem arquivos sem dono ou grupo"
(find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | grep -q . && echo "⚠️ REPROVADO") || echo "✅ APROVADO"

echo -e "\n[300] Verifique se existem arquivos SUID/SGID (revisão manual)"
(find / -xdev -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | grep -q . && echo "⚠️ REPROVADO (revisar)") || echo "✅ APROVADO"

echo -e "\n[301] Verifique se contas usam shadowed passwords"
(awk -F: '($2 != "x") {exit 1}' /etc/passwd && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[302] Verifique se não há senhas vazias em /etc/shadow"
(awk -F: '($2 == "") {exit 1}' /etc/shadow && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[303] Verifique se todos GIDs do passwd existem no group"
(awk -F: '{print $4}' /etc/passwd | sort -u | while read gid; do getent group "$gid" >/dev/null || exit 1; done && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[304] Verifique se o grupo shadow está vazio"
(awk -F: '($1=="shadow" && $NF!="") {exit 1}' /etc/group && echo "✅ APROVADO") || echo "⚠️ REPROVADO"

echo -e "\n[305] Verifique se não existem UIDs duplicados"
(cut -d: -f3 /etc/passwd | sort -n | uniq -d | grep -q . && echo "⚠️ REPROVADO") || echo "✅ APROVADO"

echo -e "\n[306] Verifique se não existem GIDs duplicados"
(cut -d: -f3 /etc/group | sort -n | uniq -d | grep -q . && echo "⚠️ REPROVADO") || echo "✅ APROVADO"

echo -e "\n[307] Verifique se não existem usuários duplicados"
(cut -d: -f1 /etc/passwd | sort | uniq -d | grep -q . && echo "⚠️ REPROVADO") || echo "✅ APROVADO"

echo -e "\n[308] Verifique se não existem grupos duplicados"
(cut -d: -f1 /etc/group | sort | uniq -d | grep -q . && echo "⚠️ REPROVADO") || echo "✅ APROVADO"

echo -e "\n[309] Verifique se diretórios home de usuários interativos estão configurados"
awk -F: '($7!~/nologin|false/ && $3>=1000 && $1!="nobody"){print $1":"$6}' /etc/passwd | \
while IFS=: read u h; do [ -d "$h" ] && stat -Lc '%a %U' "$h" | awk -v u="$u" '($1<=750 && $2==u){next} {exit 1}'; done \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[310] Verifique se dotfiles dos usuários não são inseguros"
awk -F: '($7!~/nologin|false/ && $3>=1000 && $1!="nobody"){print $6}' /etc/passwd | \
while read h; do [ -d "$h" ] && find "$h" -maxdepth 1 -type f -name '.*' -perm /022 | grep -q . && exit 1; done \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"