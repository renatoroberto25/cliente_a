#!/usr/bin/env bash

{
   l_output3=""
   l_dl=""
   unset a_output
   unset a_output2

   l_mod_name="cramfs"
   l_mod_type="fs"
   l_mod_path="$(readlink -f /lib/modules//kernel/$l_mod_type | sort -u)"

   f_module_chk() {
      l_dl="y"
      a_showconfig=()
      while IFS= read -r l_showconfig; do
         a_showconfig+=("$l_showconfig")
      done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_name//-/_}"'\b')

      if ! lsmod | grep "$l_mod_name" &>/dev/null; then
         a_output+=("✅ O módulo \"$l_mod_name\" NÃO está carregado na memória.")
      else
         a_output2+=("❗ O módulo \"$l_mod_name\" está CARREGADO na memória.")
      fi

      if grep -Pq -- '\binstall\h+'"${l_mod_name//-/_}"'\h+\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
         a_output+=("✅ O módulo \"$l_mod_name\" está BLOQUEADO via 'install /bin/true|false'.")
      else
         a_output2+=("❗ O módulo \"$l_mod_name\" ainda PODE ser carregado (não está bloqueado via 'install').")
      fi

      if grep -Pq -- '\bblacklist\h+'"${l_mod_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
         a_output+=("✅ O módulo \"$l_mod_name\" está na blacklist.")
      else
         a_output2+=("❗ O módulo \"$l_mod_name\" NÃO está na blacklist.")
      fi
   }

   for l_mod_base_directory in $l_mod_path; do
      if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-/\/}")" ]; then
         l_output3="$l_output3\n  - \"$l_mod_base_directory\""
         [[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"
         [ "$l_dl" != "y" ] && f_module_chk
      else
         a_output+=("✅ O módulo \"$l_mod_name\" não existe em \"$l_mod_base_directory\".")
      fi
   done

   echo -e "\n Verificação do módulo: \"$l_mod_name\""

   [ -n "$l_output3" ] && echo -e "\n📁 Localização detectada no sistema de arquivos:$l_output3"

   if [ "${#a_output2[@]}" -eq 0 ]; then
      echo -e "\n✅ [APROVADO] Nenhum risco identificado."
      printf '%s\n' "${a_output[@]}"
   else
      echo -e "\n⚠️  [REPROVADO] O módulo ainda representa risco."
      echo -e "\n❌ Problemas encontrados:"
      printf '%s\n' "${a_output2[@]}"
      [ "${#a_output[@]}" -gt 0 ] && echo -e "\nℹ️  Configurações corretas detectadas:" && printf '%s\n' "${a_output[@]}"
      echo -e "\n💡 Recomendações:"
      echo -e "   - Adicione ao arquivo /etc/modprobe.d/CIS.conf:"
      echo -e "     install $l_mod_name /bin/true"
      echo -e "     blacklist $l_mod_name"
      echo -e "   - Remova o módulo do disco, se necessário."
   fi
}
