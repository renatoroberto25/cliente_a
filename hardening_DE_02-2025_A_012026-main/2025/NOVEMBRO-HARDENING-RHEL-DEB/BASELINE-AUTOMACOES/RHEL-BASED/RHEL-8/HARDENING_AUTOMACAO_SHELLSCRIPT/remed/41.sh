#!/usr/bin/env bash
echo -e "\n [41] Corrigir permissões e propriedade dos arquivos grub* e user.cfg em /boot"

{
   l_output="" l_output2=""

   fix_file_perms()
   {
      l_out="" l_out2=""
      [[ "$(dirname "$l_file")" =~ ^\/boot\/efi\/EFI ]] && l_pmask="0077" || l_pmask="0177"
      l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"

      # Corrige permissões se necessário
      if [ $(( $l_mode & $l_pmask )) -gt 0 ]; then
         chmod "$l_maxperm" "$l_file" && l_out2="$l_out2\n   - Permissão corrigida para \"$l_maxperm\""
      fi

      # Corrige proprietário
      if [ "$l_user" != "root" ]; then
         chown root "$l_file" && l_out2="$l_out2\n   - Proprietário corrigido para \"root\""
      fi

      # Corrige grupo
      if [ "$l_group" != "root" ]; then
         chgrp root "$l_file" && l_out2="$l_out2\n   - Grupo corrigido para \"root\""
      fi

      [ -n "$l_out2" ] && l_output2="$l_output2\n  - Arquivo: \"$l_file\"$l_out2\n"
   }

   while IFS= read -r -d $'\0' l_gfile; do
      while read -r l_file l_mode l_user l_group; do
         fix_file_perms
      done <<< "$(stat -Lc '%n %a %U %G' "$l_gfile")"
   done < <(find /boot -type f \( -name 'grub*' -o -name 'user.cfg' \) -print0)

   if [ -z "$l_output2" ]; then
      echo -e "\n- Resultado da Remediação:\n  Nenhuma alteração foi necessária."
   else
      echo -e "\n- Resultado da Remediação:\n$l_output2"
   fi
}