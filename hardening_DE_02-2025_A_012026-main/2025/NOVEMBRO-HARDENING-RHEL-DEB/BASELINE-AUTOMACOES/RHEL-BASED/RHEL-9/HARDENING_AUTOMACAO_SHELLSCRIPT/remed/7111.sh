#!/usr/bin/env bash

log() {
    echo "[✅ SUCESSO] $1"
}
err() {
    echo "[❌ FALHA] $1"
}
{
   echo "Remediação 286 - Remover arquivos world-writable e garantir sticky bit em diretórios"

   l_smask='01000'
   a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/*" -a ! -path "/snap/*")

   while IFS= read -r l_mount; do
      while IFS= read -r -d $'\0' l_file; do
         if [ -e "$l_file" ]; then
            l_mode="$(stat -Lc '%#a' "$l_file")"

            if [ -f "$l_file" ]; then
               chmod o-w "$l_file" 2>/dev/null && \
                  log "Removido 'write' de others em arquivo: $l_file (modo atual: $l_mode)" || \
                  err "Falha ao remover 'write' em $l_file"
            fi

            if [ -d "$l_file" ]; then
               if [ ! $(( l_mode & l_smask )) -gt 0 ]; then
                  chmod a+t "$l_file" 2>/dev/null && \
                     log "Sticky bit adicionado ao diretório: $l_file (modo atual: $l_mode)" || \
                     err "Falha ao aplicar sticky bit em $l_file"
               fi
            fi
         fi
      done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2>/dev/null)
   done < <(findmnt -Dkerno fstype,target | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^(\/run\/user\/|\/tmp|\/var\/tmp)/){print $2}')

   echo "Remediação concluída"
   exit 0
}