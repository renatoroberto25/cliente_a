#!/usr/bin/env bash
echo "[273-287] Configurações de usuários e grupos locais"

check_file() {
  local id="$1" file="$2" perm="$3" owner="$4" group="$5"
  echo "[$id] Verifique se $file está configurado corretamente"
  if [ -e "$file" ]; then
    stat -Lc "%a %U %G" "$file" | awk -v p="$perm" -v u="$owner" -v g="$group" \
      '{ if ($1<=p && $2==u && $3==g) print "✅ APROVADO"; else print "⚠️ REPROVADO (atual: "$0", esperado: p,u,g)"}'
  else
    echo "⚠️ REPROVADO (arquivo não encontrado)"
  fi
}

# passwd e variantes
check_file 273 /etc/passwd     644 root root
check_file 274 /etc/passwd-    644 root root
# opasswd
check_file 275 /etc/security/opasswd     600 root root
check_file 275 /etc/security/opasswd.old 600 root root
# group e variantes
check_file 276 /etc/group      644 root root
check_file 277 /etc/group-     644 root root
# shadow e variantes
check_file 278 /etc/shadow     000 root root
check_file 279 /etc/shadow-    000 root root
# gshadow e variantes
check_file 280 /etc/gshadow    000 root root
check_file 281 /etc/gshadow-   000 root root
# shells
check_file 282 /etc/shells     644 root root
# login.defs (às vezes está junto desse bloco)
check_file 283 /etc/login.defs 644 root root
# motd e issue
check_file 284 /etc/motd       644 root root
check_file 285 /etc/issue      644 root root
check_file 286 /etc/issue.net  644 root root
# hosts.allow / hosts.deny
check_file 287 /etc/hosts.allow 644 root root
check_file 287 /etc/hosts.deny  644 root root