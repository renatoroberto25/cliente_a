#!/usr/bin/env bash
echo "[273-287] Configurações de usuários e grupos locais"
log() { echo "[✅ SUCESSO] $1"; }
err() { echo "[❌ FALHA] $1"; }

remediar_permissao() {
  local label="$1"
  local path="$2"
  local mode="$3"
  local owner="$4"
  local group="$5"

  echo "$label - Corrigindo $path"
  if [ -e "$path" ]; then
    chmod "$mode" "$path" && log "chmod $mode em $path" || err "Falha chmod em $path"
    chown "$owner:$group" "$path" && log "chown $owner:$group em $path" || err "Falha chown em $path"
  else
    log "$path não encontrado, ignorado."
  fi
}

echo "[263-287] Remediação de permissões e propriedades"

# 263–272
remediar_permissao "263" "/etc/passwd"      644 root root
remediar_permissao "264" "/etc/passwd-"     644 root root
remediar_permissao "265" "/etc/security/opasswd" 600 root root
remediar_permissao "266" "/etc/group"       644 root root
remediar_permissao "267" "/etc/group-"      644 root root
remediar_permissao "268" "/etc/shadow"      000 root root
remediar_permissao "269" "/etc/shadow-"     000 root root
remediar_permissao "270" "/etc/gshadow"     000 root root
remediar_permissao "271" "/etc/gshadow-"    000 root root
remediar_permissao "272" "/etc/shells"      644 root root

# 275
remediar_permissao "275" "/etc/security/opasswd.old" 600 root root

# 283–286
remediar_permissao "283" "/etc/login.defs" 644 root root
remediar_permissao "284" "/etc/motd"       644 root root
remediar_permissao "285" "/etc/issue"      644 root root
remediar_permissao "286" "/etc/issue.net"  644 root root

# 287 – criar se não existe
for file in /etc/hosts.allow /etc/hosts.deny; do
  if [ ! -f "$file" ]; then
    touch "$file"
    chmod 644 "$file"
    chown root:root "$file"
    log "$file criado com permissões corretas"
  else
    remediar_permissao "287" "$file" 644 root root
  fi
done

echo "✅ Remediação concluída"
exit 0