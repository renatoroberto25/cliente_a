#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

sensitive_file() { local id="$1" name="$2" file mode group=root; case "$id" in 152) file=/etc/passwd; mode=0644;; 153) file=/etc/passwd-; mode=0644;; 154) file=/etc/shadow; mode=0640; group=shadow;; 155) file=/etc/shadow-; mode=0640; group=shadow;; 156) file=/etc/gshadow-; mode=0640; group=shadow;; 157) file=/etc/gshadow; mode=0640; group=shadow;; 158) file=/etc/group; mode=0644;; 159) file=/etc/group-; mode=0644;; 160) file=/etc/security/opasswd; mode=0600;; esac; echo "[$id] $name"; [[ -e "$file" ]] || { echo "SKIP: $file ausente"; return; }; backup_file "$file"; chown root:"$group" "$file" && chmod "$mode" "$file" && echo "OK: $file" || echo "WARN: $file"; }

sensitive_file 152 'Permissões de /etc/passwd'
sensitive_file 153 'Permissões de /etc/passwd-'
sensitive_file 154 'Permissões de /etc/shadow'
sensitive_file 155 'Permissões de /etc/shadow-'
sensitive_file 156 'Permissões de /etc/gshadow-'
sensitive_file 157 'Permissões de /etc/gshadow'
sensitive_file 158 'Permissões de /etc/group'
sensitive_file 159 'Permissões de /etc/group-'
sensitive_file 160 'Proteção de /etc/security/opasswd'
