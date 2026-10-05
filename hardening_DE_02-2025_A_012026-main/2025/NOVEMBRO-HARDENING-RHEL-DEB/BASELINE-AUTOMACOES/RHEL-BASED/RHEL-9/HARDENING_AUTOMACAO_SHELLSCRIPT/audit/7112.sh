#!/usr/bin/env bash

{
   echo "287 Ensure no files or directories without an owner and a group exist"

   l_output="" l_output2=""
   a_nouser=(); a_nogroup=()
   l_excecoes=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/fs/cgroup/memory/*" -a ! -path "/var/*/private/*")

   while IFS= read -r l_mount; do
      while IFS= read -r -d $'\0' l_file; do
         if [ -e "$l_file" ]; then
            while IFS=: read -r l_user l_group; do
               [ "$l_user" = "UNKNOWN" ] && a_nouser+=("$l_file")
               [ "$l_group" = "UNKNOWN" ] && a_nogroup+=("$l_file")
            done < <(stat -Lc '%U:%G' "$l_file")
         fi
      done < <(find "$l_mount" -xdev \( "${l_excecoes[@]}" \) \( -type f -o -type d \) \( -nouser -o -nogroup \) -print0 2>/dev/null)
   done < <(findmnt -Dkerno fstype,target | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^\/run\/user\//){print $2}')

   if (( ${#a_nouser[@]} == 0 )); then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum arquivo ou diretório sem dono foi encontrado no sistema."
   else
      l_output2+=$'\n'"[⚠️[REPROVADO]]: Encontrados ${#a_nouser[@]} arquivos ou diretórios sem dono:"
      l_output2+=$'\n'"$(printf '%s\n' "${a_nouser[@]}")"
   fi

   if (( ${#a_nogroup[@]} == 0 )); then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum arquivo ou diretório sem grupo foi encontrado no sistema."
   else
      l_output2+=$'\n'"[⚠️[REPROVADO]]: Encontrados ${#a_nogroup[@]} arquivos ou diretórios sem grupo:"
      l_output2+=$'\n'"$(printf '%s\n' "${a_nogroup[@]}")"
   fi

   unset l_excecoes a_nouser a_nogroup

   if [ -z "$l_output2" ]; then
      printf '\n- Resultado da Auditoria:\n%s\n' "$l_output"
   else
      printf '\n- Resultado da Auditoria:\n%s\n' "$l_output2"
      [ -n "$l_output" ] && printf '\n- Configurações corretas:\n%s\n' "$l_output"
   fi

   exit 0
}