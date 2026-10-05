#!/usr/bin/env bash

log() { echo "[✅ SUCESSO] $1"; }
err() { echo "[❌ FALHA] $1"; }

remediar_permissao() {
  local label="$1"
  local path="$2"
  local mode="$3"
  local owner="$4"
  local group="$5"

  echo "$label - Corrigir permissões de $path"

  if [ -e "$path" ]; then
    chmod "$mode" "$path" && log "Permissões ajustadas para $mode em $path" || err "Falha ao aplicar chmod $mode em $path"
    chown "$owner:$group" "$path" && log "Propriedade ajustada para $owner:$group em $path" || err "Falha ao aplicar chown em $path"
  else
    log "Arquivo $path não encontrado, ignorado."
  fi
}

# === Controles 263 a 272 ===

remediar_permissao "263" "/etc/passwd"        644 root root
remediar_permissao "264" "/etc/passwd-"       644 root root
remediar_permissao "265" "/etc/security/opasswd" 600 root root
remediar_permissao "266" "/etc/group"         644 root root
remediar_permissao "267" "/etc/group-"        644 root root
remediar_permissao "268" "/etc/shadow"          0 root root
remediar_permissao "269" "/etc/shadow-"         0 root root
remediar_permissao "270" "/etc/gshadow"         0 root root
remediar_permissao "271" "/etc/gshadow-"        0 root root
remediar_permissao "272" "/etc/shells"       644 root root

echo "✅ Remediação concluída"
exit 0