#!/usr/bin/env bash
#MANTIDA ESTRUTURA ORIGINAL CIS"
echo "266 Ensure the audit log file directory mode is configured"
{
   l_perm_mask="0027"
   if [ -e "/etc/audit/auditd.conf" ]; then
      l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' /etc/audit/auditd.conf | xargs)")"
      if [ -d "$l_audit_log_directory" ]; then
         l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )) )"
         l_directory_mode="$(stat -Lc '%#a' "$l_audit_log_directory")"
         if [ $(( $l_directory_mode & $l_perm_mask )) -gt 0 ]; then
echo "⚠️[REPROVADO]: \"$l_audit_log_directory\" está: \"$l_directory_mode\"   (deveria ser: \"$l_maxperm\" ou mais restritivo.)"
         else
echo "✅ [APROVADO]: \"$l_audit_log_directory\" está: \"$l_directory_mode\"    (deveria ser: \"$l_maxperm\" ou mais restritivo.)"
         fi        
      else
echo "⚠️[REPROVADO]: Diretório de logs não definido em \"/etc/audit/auditd.conf\" por favor definir."
      fi
   else
echo "⚠️[REPROVADO]: Arquivo: \"/etc/audit/auditd.conf\" Não encontrado, verifique se auditd está instalado."
   fi
}