#!/usr/bin/env bash
echo "[217–224] Corrigir ownership e permissões de arquivos críticos (/etc/*)"

log() { echo "[✅ SUCESSO] $1"; }
err() { echo "[❌ FALHA] $1"; }

remediar_permissao() {
  local id="$1"
  local path="$2"
  local mode="$3"
  local owner="$4"
  local group="$5"

  echo "[$id] Verificando $path"
  if [ -e "$path" ]; then
    chmod "$mode" "$path" && log "chmod $mode em $path" || err "Falha chmod em $path"
    chown "$owner:$group" "$path" && log "chown $owner:$group em $path" || err "Falha chown em $path"
  else
    log "$path não encontrado, ignorado."
  fi
}

# ===== Remediações 217–224 =====
remediar_permissao "217" "/etc/passwd"   644 root root
remediar_permissao "218" "/etc/passwd-"  644 root root
remediar_permissao "219" "/etc/shadow"   000 root root
remediar_permissao "220" "/etc/shadow-"  000 root root
remediar_permissao "221" "/etc/gshadow-" 000 root root
remediar_permissao "222" "/etc/gshadow"  000 root root
remediar_permissao "223" "/etc/group"    644 root root
remediar_permissao "224" "/etc/group-"   644 root root

echo "✅ Remediação concluída"
exit 0
