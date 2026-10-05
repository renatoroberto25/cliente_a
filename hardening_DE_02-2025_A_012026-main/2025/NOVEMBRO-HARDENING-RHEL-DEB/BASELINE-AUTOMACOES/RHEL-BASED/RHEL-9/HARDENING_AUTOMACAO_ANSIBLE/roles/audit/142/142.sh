#!/usr/bin/env bash

{
   l_output="" l_output2=""

   file_mug_chk()
   {
      l_out="" l_out2=""
      [[ "$(dirname "$l_file")" =~ ^\/boot\/efi\/EFI ]] && l_pmask="0077" || l_pmask="0177"
      l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"

      if [ $(( $l_mode & $l_pmask )) -gt 0 ]; then
         l_out2+="❗ Permissão atual \"$l_mode\" – esperado: \"$l_maxperm\" ou mais restritivo."
      else
         l_out+="✅ Permissão correta: \"$l_mode\" (esperado: \"$l_maxperm\" ou mais restritivo)."
      fi

      if [ "$l_user" = "root" ]; then
         l_out+=" ✅ Usuário correto: \"$l_user\"."
      else
         l_out2+=" ❗ Usuário atual: \"$l_user\" – esperado: \"root\"."
      fi

      if [ "$l_group" = "root" ]; then
         l_out+=" ✅ Grupo correto: \"$l_group\"."
      else
         l_out2+=" ❗ Grupo atual: \"$l_group\" – esperado: \"root\"."
      fi

      [ -n "$l_out" ] && l_output+=$'\n'"➡️ Arquivo: \"$l_file\"\n$l_out"
      [ -n "$l_out2" ] && l_output2+=$'\n'"➡️ Arquivo: \"$l_file\"\n$l_out2"
   }

   while IFS= read -r -d $'\0' l_gfile; do
      while read -r l_file l_mode l_user l_group; do
         file_mug_chk
      done <<< "$(stat -Lc '%n %#a %U %G' "$l_gfile")"
   done < <(find /boot -type f \( -name 'grub*' -o -name 'user.cfg' \) -print0)

   if [ -z "$l_output2" ]; then
      echo -e "\n✅ Resultado da Auditoria: Todos os arquivos estão corretamente configurados."
      echo -e "$l_output"
   else
      echo -e "\n⚠️ Resultado da Auditoria: Foram encontradas configurações incorretas."
      echo -e "$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Arquivos já em conformidade:" && echo -e "$l_output"
   fi
}
