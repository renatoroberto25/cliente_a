#!/usr/bin/env bash
echo "270 Ensure audit configuration files mode is configured"
{
   l_output="" l_output2="" l_perm_mask="0137"
   l_maxperm="$( printf '%o' $(( 0777 & ~$l_perm_mask )) )"
   while IFS= read -r -d $'\0' l_fname; do
      l_mode=$(stat -Lc '%#a' "$l_fname")
      if [ $(( "$l_mode" & "$l_perm_mask" )) -gt 0 ]; then
         l_output2="$l_output2\n - arquivo: \"$l_fname\" esta com permissao: \"$l_mode\" (deveria estar com permissao: \"$l_maxperm\" ou mais restritiva)"
      fi
   done < <(find /etc/audit/ -type f \( -name "*.conf" -o -name '*.rules' \) -print0)
   if [ -z "$l_output2" ]; then
echo "✅ [APROVADO]: \"$l_maxperm\" ou mais restritiva"
   else
echo "⚠️[REPROVADO] $l_output2"
   fi
}