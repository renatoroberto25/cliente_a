#!/usr/bin/env bash
echo -e "\n [3]	Certifique-se de que o módulo do kernel hfs não esteja disponível"
{
   unset a_output2
   l_output3=""
   l_dl=""
   l_mod_name="hfs"
   l_mod_type="fs"
   l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"

   f_module_fix() {
      l_dl="y"
      a_showconfig=()
      while IFS= read -r l_showconfig; do
         a_showconfig+=("$l_showconfig")
      done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_name//-/_}"'\b')

      if lsmod | grep "$l_mod_name" &> /dev/null; then
         a_output2+=(" - descarregando módulo do kernel: \"$l_mod_name\"")
         modprobe -r "$l_mod_name" 2>/dev/null
         rmmod "$l_mod_name" 2>/dev/null
      fi
      if ! grep -Pq -- '\binstall\h+'"${l_mod_name//-/_}"'\h+\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
         a_output2+=(" - aplicando 'install $l_mod_name /bin/false'")
         printf '%s\n' "install $l_mod_name /bin/false" >> /etc/modprobe.d/"$l_mod_name".conf
      fi
      if ! grep -Pq -- '\bblacklist\h+'"${l_mod_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
         a_output2+=(" - aplicando 'blacklist $l_mod_name'")
         printf '%s\n' "blacklist $l_mod_name" >> /etc/modprobe.d/"$l_mod_name".conf
      fi
   }

   for l_mod_base_directory in $l_mod_path; do
      if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-/\/}")" ]; then
         l_output3+="\n  - \"$l_mod_base_directory\""
         [[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"
         [ "$l_dl" != "y" ] && f_module_fix
      else
         echo -e " - módulo do kernel \"$l_mod_name\" não existe em \"$l_mod_base_directory\""
      fi
   done

   [ -n "$l_output3" ] && echo -e "\n -- INFO --\n - módulo \"$l_mod_name\" localizado em:$l_output3"
   [ "${#a_output2[@]}" -gt 0 ] && printf '%s\n' "${a_output2[@]}"
   echo -e "\n✅ Remediação do módulo \"$l_mod_name\" concluída\n"
   exit 0
}
