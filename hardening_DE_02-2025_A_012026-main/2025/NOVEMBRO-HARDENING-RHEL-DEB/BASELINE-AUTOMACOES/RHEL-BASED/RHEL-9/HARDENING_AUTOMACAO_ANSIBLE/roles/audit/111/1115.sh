#!/usr/bin/env bash

{
   l_output3="" l_dl="" # limpar variáveis
   unset a_output; unset a_output2 # desfazer arrays
   l_mod_name="jffs2" # definir nome do módulo
   l_mod_type="fs" # definir tipo do módulo
   l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"
   f_module_chk()
   {
      l_dl="y" # Definir para ignorar verificações duplicadas
      a_showconfig=() # Criar array com saída do modprobe
      while IFS= read -r l_showconfig; do
         a_showconfig+=("$l_showconfig")
      done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_name//-/_}"'\b')
      if ! lsmod | grep "$l_mod_name" &> /dev/null; then # Verificar se o módulo está carregado
         a_output+=("  - módulo do kernel: \"$l_mod_name\" não está carregado")
      else
         a_output2+=("  - módulo do kernel: \"$l_mod_name\" está carregado")
      fi
      if grep -Pq -- '\binstall\h+'"${l_mod_name//-/_}"'\h+\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
         a_output+=("  - módulo do kernel: \"$l_mod_name\" não é carregável")
      else
         a_output2+=("  - módulo do kernel: \"$l_mod_name\" é carregável")
      fi
      if grep -Pq -- '\bblacklist\h+'"${l_mod_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
         a_output+=("  - módulo do kernel: \"$l_mod_name\" está na lista de negação")
      else
         a_output2+=("  - módulo do kernel: \"$l_mod_name\" não está na lista de negação")
      fi
   }
   for l_mod_base_directory in $l_mod_path; do # Verificar se o módulo existe no sistema
      if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] && [ -n "$(ls -A $l_mod_base_directory/${l_mod_name/-/\/})" ]; then
         l_output3="$l_output3\n  - \"$l_mod_base_directory\""
         [[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"        
         [ "$l_dl" != "y" ] && f_module_chk
      else
         a_output+=(" - módulo do kernel: \"$l_mod_name\" não existe em \"$l_mod_base_directory\"")
      fi
   done
   [ -n "$l_output3" ] && echo -e "\n\n -- INFO --\n - módulo: \"$l_mod_name\" existe em:$l_output3"
   if [ "${#a_output2[@]}" -le 0 ]; then
      printf '%s\n' "" "- Resultado da Auditoria:" " ✅ [APROVADO]:" "${a_output[@]}"
   else
      printf '%s\n' "" "- Resultado da Auditoria:" " ⚠️[REPROVADO]" " - Motivo(s) da falha na auditoria:" "${a_output2[@]}"
      [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Configurado corretamente:" "${a_output[@]}"
   fi
}