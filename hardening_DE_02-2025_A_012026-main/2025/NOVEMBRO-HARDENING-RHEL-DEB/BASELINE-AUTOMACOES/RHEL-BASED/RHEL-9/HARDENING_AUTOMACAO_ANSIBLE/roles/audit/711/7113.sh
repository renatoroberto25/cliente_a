#!/usr/bin/env bash

{
   echo "288 Ensure SUID and SGID files are reviewed"

   l_output="" l_output2=""
   a_suid=(); a_sgid=()

   while IFS= read -r l_mount; do
      while IFS= read -r -d $'\0' l_file; do
         if [ -e "$l_file" ]; then
            l_mode="$(stat -Lc '%#a' "$l_file")"
            [ $(( l_mode & 04000 )) -gt 0 ] && a_suid+=("$l_file")
            [ $(( l_mode & 02000 )) -gt 0 ] && a_sgid+=("$l_file")
         fi
      done < <(find "$l_mount" -xdev -type f \( -perm -4000 -o -perm -2000 \) -print0 2>/dev/null)
   done < <(findmnt -Dkerno fstype,target,options | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^\/run\/user\// && $3 !~/noexec/ && $3 !~/nosuid/) {print $2}')

   if (( ${#a_suid[@]} == 0 )); then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum arquivo com bit SUID encontrado no sistema."
   else
      l_output2+=$'\n'"[⚠️[REPROVADO]]: Encontrados ${#a_suid[@]} arquivos com bit SUID:"
      l_output2+=$'\n'"$(printf '%s\n' "${a_suid[@]}")"
   fi

   if (( ${#a_sgid[@]} == 0 )); then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum arquivo com bit SGID encontrado no sistema."
   else
      l_output2+=$'\n'"[⚠️[REPROVADO]]: Encontrados ${#a_sgid[@]} arquivos com bit SGID:"
      l_output2+=$'\n'"$(printf '%s\n' "${a_sgid[@]}")"
   fi

   if [ -n "$l_output2" ]; then
      l_output2+=$'\n'"[⚠️ REVISÃO NECESSÁRIA]: Verifique os arquivos listados acima para garantir que são legítimos e não foram introduzidos maliciosamente no sistema."
   fi

   unset a_suid a_sgid

   if [ -z "$l_output2" ]; then
      printf '\n- Resultado da Auditoria:\n%s\n' "$l_output"
   else
      printf '\n- Resultado da Auditoria:\n%s\n' "$l_output2"
      [ -n "$l_output" ] && printf '\n- Configurações corretas:\n%s\n' "$l_output"
   fi

   exit 0
}