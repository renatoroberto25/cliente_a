#!/usr/bin/env bash
# [263-272 + extras] Remediação segura de permissões/owner em arquivos sensíveis
# Política: backup -> altera só se necessário -> mantém execução até o fim

set -uo pipefail
TS="$(date +%Y%m%d-%H%M%S)"
log(){ echo "✔ $1"; }
warn(){ echo "⚠️ $1"; }
fail(){ echo "✖ $1"; }

backup_file(){
  local f="$1"
  [ -e "$f" ] || { warn "$f ausente (ignorado)"; return 0; }
  cp -a -- "$f" "${f}.bkp-${TS}" && log "Backup: ${f}.bkp-${TS}" || warn "Falha backup $f"
}

needs_change(){
  # usage: needs_change <path> <mode> <owner> <group>
  local f="$1" m="$2" u="$3" g="$4"
  [ -e "$f" ] || return 1
  cur="$(stat -Lc '%a %U %G' -- "$f" 2>/dev/null || echo '')"
  [ -z "$cur" ] && return 0
  IFS=' ' read -r cm cu cg <<<"$cur"
  [ "$cm" != "$m" ] || [ "$cu" != "$u" ] || [ "$cg" != "$g" ]
}

fix_one(){
  local lbl="$1" f="$2" m="$3" u="$4" g="$5"
  echo "[$lbl] Corrigindo $f → $m $u $g"
  [ -e "$f" ] || { warn "$f não encontrado (ignorado)"; return 0; }
  backup_file "$f"
  # muda só se necessário
  needs_change "$f" "$m" "$u" "$g" || { log "$f já conforme"; return 0; }
  chmod "$m" -- "$f" && log "chmod $m $f" || fail "chmod $f"
  chown "$u:$g" -- "$f" && log "chown $u:$g $f" || fail "chown $f"
  # Se SELinux em enforcing, restaura contextos
  command -v restorecon >/dev/null 2>&1 && restorecon -F "$f" >/dev/null 2>&1 || true
}

echo "[263-272] Remediação de permissões e propriedades"

# 263–272 (mantendo a tua baseline: shadow/gshadow como 000 root:root no OL8)
fix_one 263 /etc/passwd      644 root root
fix_one 264 /etc/passwd-     644 root root
fix_one 265 /etc/security/opasswd 600 root root
fix_one 266 /etc/group       644 root root
fix_one 267 /etc/group-      644 root root
fix_one 268 /etc/shadow      000 root root
fix_one 269 /etc/shadow-     000 root root
fix_one 270 /etc/gshadow     000 root root
fix_one 271 /etc/gshadow-    000 root root
fix_one 272 /etc/shells      644 root root

echo "[extras] Itens comuns no teu bloco"
fix_one 283 /etc/login.defs  644 root root
fix_one 284 /etc/motd        644 root root
fix_one 285 /etc/issue       644 root root
fix_one 286 /etc/issue.net   644 root root

echo "[287] /etc/hosts.allow / /etc/hosts.deny"
for f in /etc/hosts.allow /etc/hosts.deny; do
  if [ ! -e "$f" ]; then
    backup_file "$f" 2>/dev/null || true
    : > "$f" && log "Criado $f"
  fi
  fix_one 287 "$f" 644 root root
done

echo "✔ Remediação (263-272 + extras) concluída"
exit 0