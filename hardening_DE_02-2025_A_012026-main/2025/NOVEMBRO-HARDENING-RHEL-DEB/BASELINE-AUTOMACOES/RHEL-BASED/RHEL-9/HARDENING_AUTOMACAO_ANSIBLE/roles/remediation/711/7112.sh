#!/usr/bin/env bash

log() { echo "[✅ SUCESSO] $1"; }
err() { echo "[❌ FALHA] $1"; }

echo "Remediação 287 - Corrigir arquivos/diretórios sem owner ou grupo"

a_path=(! -path "/proc/*" -a ! -path "/run/user/*" -a ! -path "/sys/*")

while IFS= read -r l_mount; do
  while IFS= read -r -d $'\0' l_file; do
    if [ ! -e "$l_file" ]; then continue; fi

    l_stat=$(stat -Lc '%U:%G' "$l_file")
    l_user=${l_stat%:*}
    l_group=${l_stat#*:}

    if [[ "$l_user" = "UNKNOWN" ]]; then
      chown root "$l_file" && log "Dono ajustado para root em $l_file" || err "Falha ao ajustar dono de $l_file"
    fi
    if [[ "$l_group" = "UNKNOWN" ]]; then
      chgrp root "$l_file" && log "Grupo ajustado para root em $l_file" || err "Falha ao ajustar grupo de $l_file"
    fi

  done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -nouser -o -nogroup \) -print0 2>/dev/null)
done < <(findmnt -Dkerno fstype,target | awk '$1 !~ /^(nfs|proc|vfat|iso9660)/ {print $2}')

echo "✅ Remediação concluída"