#!/usr/bin/env bash

check_permissions() {
   local label="$1"             # Ex: 276
   local filepath="$2"          # Ex: /etc/passwd
   local expected_perm="$3"     # Ex: 644 ou 0
   local expected_uid="$4"      # root = 0
   local expected_gid="$5"      # root = 0
   local must_exist="${6:-yes}" # default: sim, o arquivo deve existir

   echo "$label Ensure permissions on $filepath are configured"

   local l_output="" l_output2=""

   if [ ! -e "$filepath" ]; then
      if [ "$must_exist" = "yes" ]; then
         l_output2+=$'\n'"[⚠️[REPROVADO]]: O arquivo $filepath não existe neste sistema."
      else
         l_output+=$'\n'"[⚠️ IGNORADO]: O arquivo $filepath não existe neste sistema."
      fi
   else
      local stat_info perm uid gid
      stat_info=$(stat -Lc 'Access: (%#a/%A)  Uid: (%u/%U) Gid: (%g/%G)' "$filepath")
      perm=$(stat -Lc '%a' "$filepath")
      uid=$(stat -Lc '%u' "$filepath")
      gid=$(stat -Lc '%g' "$filepath")

      if [ "$perm" -le "$expected_perm" ] && [ "$uid" -eq "$expected_uid" ] && [ "$gid" -eq "$expected_gid" ]; then
         l_output+=$'\n'"✅ [APROVADO]: $filepath está corretamente configurado (perm: $perm, owner: $uid, group: $gid)."
      else
         l_output2+=$'\n'"[⚠️[REPROVADO]]: Permissões ou propriedade incorretas em $filepath."
         l_output2+=$'\n'"- Detalhes: $stat_info"
      fi
   fi

   # Exibe resultado
   if [ -z "$l_output2" ]; then
      printf '\n- Resultado da Auditoria (%s):\n%s\n' "$label" "$l_output"
   else
      printf '\n- Resultado da Auditoria (%s):\n%s\n' "$label" "$l_output2"
      [ -n "$l_output" ] && printf '\n- Configurações corretas:\n%s\n' "$l_output"
   fi
}

# === Chamadas por controle ===

check_permissions "276" "/etc/passwd" 644 0 0
check_permissions "277" "/etc/passwd-" 644 0 0 "no"
check_permissions "278" "/etc/group" 644 0 0
check_permissions "279" "/etc/group-" 644 0 0 "no"
check_permissions "280" "/etc/shadow" 0 0 0
check_permissions "281" "/etc/shadow-" 0 0 0 "no"
check_permissions "282" "/etc/gshadow" 0 0 0
check_permissions "283" "/etc/gshadow-" 0 0 0 "no"
check_permissions "284" "/etc/shells" 644 0 0

# 285: múltiplos arquivos opcionais com mesma regra
check_permissions "285" "/etc/security/opasswd" 600 0 0 "no"
check_permissions "285" "/etc/security/opasswd.old" 600 0 0 "no"

exit 0