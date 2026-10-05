#!/usr/bin/env bash

{
   l_output="" l_output2=""
   l_perm_mask="0177"
   if [ -e "/etc/audit/auditd.conf" ]; then
      l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' /etc/audit/auditd.conf | xargs)")"
      if [ -d "$l_audit_log_directory" ]; then
         l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )) )"
         while IFS= read -r -d $'\0' l_file; do
            l_output2="$l_output2 Arquivo \"$l_file\" está: \"$(stat -Lc '%#a' "$l_file")\" , deveria ser \"$l_maxperm\" ou mais restritivo."
         done < <(find "$l_audit_log_directory" -maxdepth 1 -type f -perm /"$l_perm_mask" -print0)
      else
         l_output2="$l_output2 Diretório não setado em \"/etc/audit/auditd.conf\" configurar o diretório."
      fi
   else
      l_output2="$l_output2 Arquivo \"/etc/audit/auditd.conf\" não encontrad. - Verificar se auditd está instalado."
   fi
   if [ -z "$l_output2" ]; then
      l_output="$l_output Todos arquivos em \"$l_audit_log_directory\" estão \"$l_maxperm\" ou mais restritivo."
echo "✅ [APROVADO]: $l_output"
   else
echo "⚠️[REPROVADO]: $l_output2"
   fi
}