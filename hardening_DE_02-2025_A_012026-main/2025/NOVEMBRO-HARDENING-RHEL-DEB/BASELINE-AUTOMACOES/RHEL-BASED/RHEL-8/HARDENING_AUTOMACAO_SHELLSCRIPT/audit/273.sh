#!/usr/bin/env bash

echo -e "[273] Verifique se não existem arquivos/diretórios world-writable sem sticky bit"
( find / \( -path /proc -o -path /sys -o -path /run -o -path /dev -o -path /snap -o -path /var/lib/docker \) -prune -o \( -type f -perm -0002 -print -o -type d -perm -0002 ! -perm -1000 -print \) -print -quit 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[274] Verifique se não existem arquivos/diretórios sem dono ou sem grupo"
( find / \( -path /proc -o -path /sys -o -path /run -o -path /dev -o -path /snap -o -path /var/lib/docker \) -prune -o \( -type f -o -type d \) \( -nouser -o -nogroup \) -print -quit 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[275] Liste SUID/SGID files para revisão (audit)"
( find / \( -path /proc -o -path /sys -o -path /run -o -path /dev -o -path /snap -o -path /var/lib/docker \) -prune -o -xdev -type f \( -perm -4000 -o -perm -2000 \) -print -quit 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO (SUID/SGID encontrados - revisar)" || echo "✅ APROVADO"

echo -e "\n[276] Audite permissões via rpm -Va (may be slow)"
( rpm -Va --nomtime --nosize --nomd5 --nolinkto --noconfig --noghost 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO (rpm -Va encontrou diferenças)" || echo "✅ APROVADO"

echo -e "\n[277] Verifique se as contas em /etc/passwd usam senhas sombreadas (campo 2 == 'x')"
( awk -F: '($2 != "x"){exit 1}' /etc/passwd ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[278] Verifique se não existem campos de senha vazios em /etc/shadow"
( grep -qE '^[^:]+::' /etc/shadow 2>/dev/null ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[279] Verifique se todos os grupos em /etc/passwd existem em /etc/group"
( cut -d: -f4 /etc/passwd | sort -u | while read -r GID; do getent group "$GID" >/dev/null 2>&1 || exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[280] Verifique se não existem UIDs duplicados"
( cut -d: -f3 /etc/passwd | sort -n | uniq -d | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[281] Verifique se não existem GIDs duplicados"
( cut -d: -f3 /etc/group | sort -n | uniq -d | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[282] Verifique se não existem nomes de usuário duplicados"
( cut -d: -f1 /etc/passwd | sort | uniq -d | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[283] Verifique se não existem nomes de grupo duplicados"
( cut -d: -f1 /etc/group | sort | uniq -d | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[284] Verifique a integridade do PATH do root ('.', '::', trailing ':' , paths existentes, owned by root, perms <=0755)"
( set -e; P=$(sudo -Hiu root env | grep '^PATH=' | cut -d= -f2); echo "$P" | grep -qE '(^|:)(\.|:|$)' && exit 1; echo "$P" | tr ':' '\n' | while read -r p; do [ -d "$p" ] || exit 1; [ "$(stat -Lc %U "$p" 2>/dev/null)" = "root" ] || exit 1; [ "$(stat -Lc %a "$p" 2>/dev/null)" -le 755 ] || exit 1; done; ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[285] Verifique se apenas root possui UID 0"
( awk -F: '($3 == 0){print $1}' /etc/passwd | wc -l | grep -q '^1$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[286] Verifique se diretórios HOME de usuários interativos existem/possuem owner correto/perms 750 ou mais restritivo"
( awk -F: '($7 !~ /(nologin|false)$/ && $3 >= 1000){print $1 ":" $(NF-1)}' /etc/passwd | while IFS=: read -r u h; do [ -d "$h" ] || exit 1; [ "$(stat -Lc %U "$h" 2>/dev/null)" = "$u" ] || exit 1; [ "$(stat -Lc %a "$h" 2>/dev/null)" -le 750 ] || exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[287] Verifique dotfiles inseguros em home de usuários interativos (.rhost, .forward, .netrc, .bash_history perms)"
( awk -F: '($7 !~ /(nologin|false)$/ && $3 >= 1000){print $1 ":" $(NF-1)}' /etc/passwd | while IFS=: read -r u h; do for f in .rhosts .forward; do [ -f \"$h/$f\" ] && exit 1; done; [ -f \"$h/.netrc\" ] && [ \"$(stat -Lc %a \"$h/.netrc\")\" -gt 600 ] && exit 1; [ -f \"$h/.bash_history\" ] && [ \"$(stat -Lc %a \"$h/.bash_history\")\" -gt 600 ] && exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"