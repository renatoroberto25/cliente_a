#!/usr/bin/env bash

{
   echo "297 Ensure local interactive user dot files access is configured"

   l_output="" l_output2="" l_warn=""
   l_mask_netrc='0177'     # máx: 600
   l_mask_general='0133'   # máx: 644

   valid_shells=$(grep -vE 'nologin|false' /etc/shells | grep '^/' | tr '\n' '|')
   valid_shells="${valid_shells%|}"

   mapfile -t users < <(grep -E ":/home/.+:($valid_shells)$" /etc/passwd | cut -d: -f1,6)

   for entry in "${users[@]}"; do
      l_user="${entry%%:*}"
      l_home="${entry#*:}"

      [ ! -d "$l_home" ] && continue

      user_gid=$(id -g "$l_user")
      files=$(find "$l_home" -xdev -type f -name '.*' 2>/dev/null)

      for file in $files; do
         name=$(basename "$file")
         perms=$(stat -Lc '%a' "$file" 2>/dev/null)
         owner=$(stat -Lc '%U' "$file" 2>/dev/null)

         # Arquivos proibidos
         if [[ "$name" == ".rhosts" || "$name" == ".forward" ]]; then
            l_output2+=$'\n'"[⚠️[REPROVADO]]: Arquivo proibido \"$file\" encontrado."
            continue
         fi

         # .netrc precisa ser <= 600
         if [[ "$name" == ".netrc" ]]; then
            if [ $(( 8#$perms & l_mask_netrc )) -gt 0 ]; then
               l_output2+=$'\n'"[⚠️[REPROVADO]]: \"$file\" tem permissões \"$perms\". Esperado: até 600."
            fi
            [ "$owner" != "$l_user" ] && l_output2+=$'\n'"[⚠️[REPROVADO]]: \"$file\" não é de propriedade de \"$l_user\" (atual: $owner)."
            continue
         fi

         # .bash_history também sensível
         if [[ "$name" == ".bash_history" ]]; then
            if [ $(( 8#$perms & l_mask_netrc )) -gt 0 ]; then
               l_output2+=$'\n'"[⚠️[REPROVADO]]: \"$file\" (.bash_history) tem permissões \"$perms\". Esperado: até 600."
            fi
         fi

         # Verificação geral para qualquer dotfile
         if [ $(( 8#$perms & l_mask_general )) -gt 0 ]; then
            l_output2+=$'\n'"[⚠️[REPROVADO]]: \"$file\" tem permissões \"$perms\". Esperado: até 644."
         fi
         [ "$owner" != "$l_user" ] && l_output2+=$'\n'"[⚠️[REPROVADO]]: \"$file\" não é de propriedade de \"$l_user\" (atual: $owner)."
      done
   done

   if [ -z "$l_output2" ]; then
      echo -e "\n- Resultado da Auditoria (297):\n✅ [APROVADO]: Todos os dotfiles estão configurados corretamente."
   else
      echo -e "\n- Resultado da Auditoria (297):\n$l_output2"
   fi

   exit 0
}