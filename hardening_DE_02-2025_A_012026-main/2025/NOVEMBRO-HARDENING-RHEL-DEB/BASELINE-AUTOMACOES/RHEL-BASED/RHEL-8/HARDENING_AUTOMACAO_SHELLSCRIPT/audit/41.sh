#!/usr/bin/env bash
echo -e "\n [41] Garantir que os arquivos de boot (grub* e user.cfg) possuam permissões restritas"
{
   l_output="" l_output2=""
   file_mug_chk()
   {
      l_out="" l_out2=""
      # Determina a máscara de permissão (diferente se for EFI)
      [[ "$(dirname "$l_file")" =~ ^\/boot\/efi\/EFI ]] && l_pmask="0077" || l_pmask="0177"
      l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"
      # Verifica permissões
      if [ $(( $l_mode & $l_pmask )) -gt 0 ]; then
         l_out2="$l_out2\n   - Permissão atual \"$l_mode\" não é restrita (esperado: \"$l_maxperm\" ou mais restritivo)"
      else
         l_out="$l_out\n   - Permissão correta: \"$l_mode\" (esperado: \"$l_maxperm\" ou mais restritivo)"
      fi
      # Verifica usuário
      if [ "$l_user" = "root" ]; then
         l_out="$l_out\n   - Usuário proprietário correto: \"$l_user\""
      else
         l_out2="$l_out2\n   - Usuário proprietário incorreto: \"$l_user\" (esperado: \"root\")"
      fi
      # Verifica grupo
      if [ "$l_group" = "root" ]; then
         l_out="$l_out\n   - Grupo proprietário correto: \"$l_group\""
      else
         l_out2="$l_out2\n   - Grupo proprietário incorreto: \"$l_group\" (esperado: \"root\")"
      fi
      # Acumula resultados
      [ -n "$l_out" ] && l_output="$l_output\n  - Arquivo: \"$l_file\"$l_out\n"
      [ -n "$l_out2" ] && l_output2="$l_output2\n  - Arquivo: \"$l_file\"$l_out2\n"
   }
   # Encontra os arquivos e processa com stat
   while IFS= read -r -d $'\0' l_gfile; do
      while read -r l_file l_mode l_user l_group; do
         file_mug_chk
      done <<< "$(stat -Lc '%n %#a %U %G' "$l_gfile")"
   done < <(find /boot -type f \( -name 'grub*' -o -name 'user.cfg' \) -print0)
   # Saída final
   if [ -z "$l_output2" ]; then
      echo -e "\n- Resultado da Auditoria:\n  ✅ APROVADO\n$l_output"
   else
      echo -e "\n- Resultado da Auditoria:\n  ⚠️ REPROVADO\n$l_output2"
      [ -n "$l_output" ] && echo -e "- Configurações corretas detectadas:\n$l_output"
   fi
}