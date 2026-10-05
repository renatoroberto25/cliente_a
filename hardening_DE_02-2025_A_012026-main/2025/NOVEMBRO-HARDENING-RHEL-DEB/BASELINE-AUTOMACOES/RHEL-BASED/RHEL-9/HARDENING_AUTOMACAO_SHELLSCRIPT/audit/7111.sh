#!/usr/bin/env bash

{
   echo "286 Ensure world writable files and directories are secured"

   l_output="" l_output2=""
   l_smask='01000'
   a_file=(); a_dir=()
   a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/*" -a ! -path "/snap/*")

   while IFS= read -r l_mount; do
      while IFS= read -r -d $'\0' l_file; do
         if [ -e "$l_file" ]; then
            [ -f "$l_file" ] && a_file+=("$l_file")
            if [ -d "$l_file" ]; then
               l_mode="$(stat -Lc '%#a' "$l_file")"
               [ ! $(( l_mode & l_smask )) -gt 0 ] && a_dir+=("$l_file")
            fi
         fi
      done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2>/dev/null)
   done < <(findmnt -Dkerno fstype,target | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^(\/run\/user\/|\/tmp|\/var\/tmp)/){print $2}')

   if (( ${#a_file[@]} == 0 )); then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum arquivo world-writable encontrado no sistema local."
   else
      l_output2+=$'\n'"[⚠️[REPROVADO]]: Encontrados ${#a_file[@]} arquivos world-writable:"
      l_output2+=$'\n'"$(printf '%s\n' "${a_file[@]}")"
   fi

   if (( ${#a_dir[@]} == 0 )); then
      l_output+=$'\n'"✅ [APROVADO]: Todos os diretórios world-writable possuem o sticky bit corretamente configurado."
   else
      l_output2+=$'\n'"[⚠️[REPROVADO]]: Encontrados ${#a_dir[@]} diretórios world-writable sem sticky bit:"
      l_output2+=$'\n'"$(printf '%s\n' "${a_dir[@]}")"
   fi

   unset a_path a_file a_dir

   if [ -z "$l_output2" ]; then
      printf '\n- Resultado da Auditoria:\n%s\n' "$l_output"
      echo "Confirmar se existe alguma limitação de montagem que impeça o chmod a+t de ser efetivo."
   else
      printf '\n- Resultado da Auditoria:\n%s\n' "$l_output2"
      echo "Confirmar se existe alguma limitação de montagem que impeça o chmod a+t de ser efetivo."
      [ -n "$l_output" ] && printf '\n- Configurações corretas:\n%s\n' "$l_output"
   fi
   exit 0
}