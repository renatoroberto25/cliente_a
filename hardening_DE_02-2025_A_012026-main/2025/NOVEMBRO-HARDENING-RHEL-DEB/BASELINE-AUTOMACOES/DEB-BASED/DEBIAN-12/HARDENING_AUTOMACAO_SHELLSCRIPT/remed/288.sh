#!/usr/bin/env bash
echo -e "\n[288–297] Corrigindo permissões de arquivos sensíveis"

fix_perms() {
  local file="$1" mode="$2" owner="$3" group="$4"
  [ -e "$file" ] || return 0
  chmod "$mode" "$file"
  chown "$owner:$group" "$file"
  echo "  Corrigido $file → $mode $owner:$group"
}

fix_perms /etc/passwd 644 root root
fix_perms /etc/passwd- 644 root root
fix_perms /etc/group 644 root root
fix_perms /etc/group- 644 root root
fix_perms /etc/shadow 640 root shadow
fix_perms /etc/shadow- 640 root shadow
fix_perms /etc/gshadow 640 root shadow
fix_perms /etc/gshadow- 640 root shadow
fix_perms /etc/shells 644 root root
fix_perms /etc/security/opasswd 600 root root
fix_perms /etc/security/opasswd.old 600 root root