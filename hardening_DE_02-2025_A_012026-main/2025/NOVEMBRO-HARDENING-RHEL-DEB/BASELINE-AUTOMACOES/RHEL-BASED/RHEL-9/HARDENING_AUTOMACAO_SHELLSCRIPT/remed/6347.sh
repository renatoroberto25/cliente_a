#!/usr/bin/env bash

echo "272 Ensure audit configuration files group owner is configured"
arquivos_nao_root=$(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) ! -group root)

# Verifica se a variável arquivos_nao_root contém alguma coisa
if [ -n "$arquivos_nao_root" ]; then
  echo "Os seguintes arquivos não pertencem ao grupo root:"
  echo "$arquivos_nao_root"
  find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) ! -group root -exec chgrp root {} +
  echo "⚠️ Executado chgrp root."
else
  echo "[✅ SUCESSO]: - Todos os arquivos .conf e .rules em /etc/audit/ pertencem ao grupo root."
fi

echo "273 Ensure audit tools mode is configured"
{
   l_output="" l_output2="" l_perm_mask="0022"
   l_maxperm="$( printf '%o' $(( 0777 & ~$l_perm_mask )) )"
   a_audit_tools=("/sbin/auditctl" "/sbin/aureport" "/sbin/ausearch" "/sbin/autrace" "/sbin/auditd" "/sbin/augenrules")

   for l_audit_tool in "${a_audit_tools[@]}"; do
      l_mode="$(stat -Lc '%#a' "$l_audit_tool")"
      if [ $(( l_mode & l_perm_mask )) -gt 0 ]; then
         l_output2="$l_output2\n - Ferramenta \"$l_audit_tool\" está com permissões: \"$l_mode\" e devia estar: \"$l_maxperm\" ou mais restrito"
      else
         l_output="$l_output\n - Ferramenta \"$l_audit_tool\" com permissionamento adequado: \"$l_mode\""
      fi
   done

   if [ -z "$l_output2" ]; then
      echo -e "✅ APROVADO - $l_output"
   else
      echo -e "⚠️[REPROVADO] -$l_output2"
      [ -n "$l_output" ] && echo -e "\n - Com permissionamento adequado:\n$l_output\n"
      echo "Removendo permissões de escrita para grupo e outros"
      chmod go-w "${a_audit_tools[@]}"
   fi

   unset a_audit_tools
}