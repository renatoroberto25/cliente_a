#!/usr/bin/env bash

{
   echo "296 Ensure local interactive user home directories are configured"

   l_output="" l_output2=""
   l_haout2="" l_hoout2="" l_heout2=""
   l_mask='0027'
   l_max="$(printf '%o' $(( 0777 & ~$l_mask )) )"

   # Lista de shells válidos
   valid_shells=$(grep -vE 'nologin|false' /etc/shells | grep '^/' | tr '\n' '|')
   valid_shells="${valid_shells%|}"  # Remove último "|"

   # Obter usuários locais interativos
   mapfile -t a_uarr < <(grep -E ":/home/.+:($valid_shells)$" /etc/passwd | cut -d: -f1,6)

   for entry in "${a_uarr[@]}"; do
      l_user="${entry%%:*}"
      l_home="${entry#*:}"

      if [ -d "$l_home" ]; then
         # ⚠️ Aqui usamos %a no lugar de %#a para evitar prefixos problemáticos
         l_stat=$(stat -Lc '%U %a' "$l_home" 2>/dev/null)
         l_owner=$(cut -d' ' -f1 <<< "$l_stat")
         l_mode=$(cut -d' ' -f2 <<< "$l_stat")

         [ "$l_owner" != "$l_user" ] && l_hoout2+=$'\n'"[⚠️[REPROVADO]]: Usuário \"$l_user\" - diretório home \"$l_home\" é de propriedade de \"$l_owner\"."
         if [ $(( 8#$l_mode & 8#$l_mask )) -gt 0 ]; then
            l_haout2+=$'\n'"[⚠️[REPROVADO]]: Usuário \"$l_user\" - diretório home \"$l_home\" tem permissões \"$l_mode\". Esperado: \"$l_max\" ou mais restritivas."
         fi
      else
         l_heout2+=$'\n'"[⚠️[REPROVADO]]: Usuário \"$l_user\" - diretório home \"$l_home\" não existe."
      fi
   done

   # Aprovações
   [ -z "$l_heout2" ] && l_output+=$'\n'"✅ [APROVADO]: Todos os diretórios home existem."
   [ -z "$l_hoout2" ] && l_output+=$'\n'"✅ [APROVADO]: Todos os diretórios home são de propriedade do respectivo usuário."
   [ -z "$l_haout2" ] && l_output+=$'\n'"✅ [APROVADO]: Todos os diretórios home possuem permissões iguais ou mais restritivas que $l_max."

   # Reprovações
   [ -n "$l_heout2" ] && l_output2+="$l_heout2"
   [ -n "$l_hoout2" ] && l_output2+="$l_hoout2"
   [ -n "$l_haout2" ] && l_output2+="$l_haout2"

   # Resultado final
   if [ -z "$l_output2" ]; then
      printf '\n- Resultado da Auditoria (296):\n%s\n' "$l_output"
   else
      printf '\n- Resultado da Auditoria (296):\n%s\n' "$l_output2"
      [ -n "$l_output" ] && printf '\n- Configurações corretas:\n%s\n' "$l_output"
   fi

   exit 0
}