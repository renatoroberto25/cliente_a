#!/usr/bin/env bash

{
   echo "297 Remediação: Corrigir permissões e propriedade de arquivos ocultos (dotfiles) em diretórios home de usuários interativos locais"

   l_output=""
   l_mask_netrc='0177'     # máx: 600
   l_mask_general='0133'   # máx: 644

   valid_shells=$(grep -vE 'nologin|false' /etc/shells | grep '^/' | tr '\n' '|')
   valid_shells="${valid_shells%|}"

   mapfile -t users <<< "$(grep -E ":/home/.+:($valid_shells)$" /etc/passwd | cut -d: -f1,6)"

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
         group=$(stat -Lc '%G' "$file" 2>/dev/null)

         # Arquivos proibidos
         if [[ "$name" == ".rhosts" || "$name" == ".forward" ]]; then
            l_output+=$'\n'"⚠️ [AVISO]: Arquivo proibido \"$file\" encontrado. Favor revisar e remover manualmente."
            continue
         fi

         # Permissões esperadas
         if [[ "$name" == ".netrc" || "$name" == ".bash_history" ]]; then
            l_mask=$l_mask_netrc
            l_expected="600"
            l_change="u-x,go-rwx"
         else
            l_mask=$l_mask_general
            l_expected="644"
            l_change="u-x,go-wx"
         fi

         # Corrigir permissões
         if [ $(( 8#$perms & l_mask )) -gt 0 ]; then
            if chmod $l_change "$file" 2>/dev/null; then
               l_output+=$'\n'"✅ [SUCESSO]: Permissões de \"$file\" ajustadas para no máximo \"$l_expected\"."
            else
               l_output+=$'\n'"❌ [FALHA]: Não foi possível ajustar permissões de \"$file\"."
            fi
         fi

         # Corrigir propriedade
         if [ "$owner" != "$l_user" ]; then
            if chown "$l_user" "$file" 2>/dev/null; then
               l_output+=$'\n'"✅ [SUCESSO]: Propriedade de \"$file\" corrigida para \"$l_user\"."
            else
               l_output+=$'\n'"❌ [FALHA]: Não foi possível alterar a propriedade de \"$file\" para \"$l_user\"."
            fi
         fi

         # Corrigir grupo
         if [ "$group" != "$l_user" ] && [ "$group" != "$(id -gn "$l_user")" ]; then
            if chgrp "$(id -gn "$l_user")" "$file" 2>/dev/null; then
               l_output+=$'\n'"✅ [SUCESSO]: Grupo de \"$file\" corrigido para \"$(id -gn "$l_user")\"."
            else
               l_output+=$'\n'"❌ [FALHA]: Não foi possível alterar o grupo de \"$file\"."
            fi
         fi
      done
   done

   if [ -z "$l_output" ]; then
      echo -e "\n✅ Nenhuma remediação foi necessária. Todos os dotfiles estavam em conformidade."
   else
      echo -e "\n- Resultado da Remediação (297):$l_output"
   fi

   exit 0
}