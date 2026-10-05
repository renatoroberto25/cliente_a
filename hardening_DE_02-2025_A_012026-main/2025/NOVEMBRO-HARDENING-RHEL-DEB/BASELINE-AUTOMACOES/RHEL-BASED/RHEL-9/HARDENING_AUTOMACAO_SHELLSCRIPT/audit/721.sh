#!/usr/bin/env bash

check_7_2_1() {
   local label="289"
   local l_output="" l_output2=""

   while IFS=: read -r user pass _; do
      if [[ "$pass" != "x" ]]; then
         l_output2+=$'\n'"[⚠️[REPROVADO]]: Usuário \"$user\" não está usando senha shadowed."
      fi
   done < /etc/passwd

   if [ -z "$l_output2" ]; then
      l_output+=$'\n'"✅ [APROVADO]: Todos os usuários utilizam senhas shadowed no /etc/passwd."
   fi

   printf '\n- Resultado da Auditoria (%s):\n%s\n' "$label" "${l_output2:-$l_output}"
}

check_7_2_2() {
   local label="290"
   local l_output="" l_output2=""

   while IFS=: read -r user pass _; do
      if [[ -z "$pass" ]]; then
         l_output2+=$'\n'"[⚠️[REPROVADO]]: Usuário \"$user\" está com campo de senha vazio no /etc/shadow."
      fi
   done < /etc/shadow

   if [ -z "$l_output2" ]; then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum usuário possui campo de senha vazio no /etc/shadow."
   fi

   printf '\n- Resultado da Auditoria (%s):\n%s\n' "$label" "${l_output2:-$l_output}"
}

check_7_2_3() {
   local label="291"
   local l_output="" l_output2=""

   mapfile -t gids_passwd < <(awk -F: '{print $4}' /etc/passwd | sort -u)
   mapfile -t gids_group < <(awk -F: '{print $3}' /etc/group | sort -u)

   for gid in "${gids_passwd[@]}"; do
      if ! printf '%s\n' "${gids_group[@]}" | grep -qx "$gid"; then
         awk -F: -v gid="$gid" '($4 == gid) {print "[⚠️[REPROVADO]]: GID \"" $4 "\" do usuário \"" $1 "\" não existe em /etc/group."}' /etc/passwd >> >(l_output2+=$(cat))
      fi
   done

   if [ -z "$l_output2" ]; then
      l_output+=$'\n'"✅ [APROVADO]: Todos os grupos referenciados em /etc/passwd existem em /etc/group."
   fi

   printf '\n- Resultado da Auditoria (%s):\n%s\n' "$label" "${l_output2:-$l_output}"
}

check_7_2_4() {
   local label="292"
   local l_output="" l_output2=""

   cut -d: -f3 /etc/passwd | sort | uniq -d | while read -r uid; do
      users=$(awk -F: -v uid="$uid" '($3 == uid) {print $1}' /etc/passwd | xargs)
      l_output2+=$'\n'"[⚠️[REPROVADO]]: UID duplicado: \"$uid\" usado por: $users"
   done

   if [ -z "$l_output2" ]; then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum UID duplicado foi encontrado."
   fi

   printf '\n- Resultado da Auditoria (%s):\n%s\n' "$label" "${l_output2:-$l_output}"
}

check_7_2_5() {
   local label="293"
   local l_output="" l_output2=""

   cut -d: -f3 /etc/group | sort | uniq -d | while read -r gid; do
      groups=$(awk -F: -v gid="$gid" '($3 == gid) {print $1}' /etc/group | xargs)
      l_output2+=$'\n'"[⚠️[REPROVADO]]: GID duplicado: \"$gid\" usado por: $groups"
   done

   if [ -z "$l_output2" ]; then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum GID duplicado foi encontrado."
   fi

   printf '\n- Resultado da Auditoria (%s):\n%s\n' "$label" "${l_output2:-$l_output}"
}

check_7_2_6() {
   local label="294"
   local l_output="" l_output2=""

   cut -d: -f1 /etc/passwd | sort | uniq -d | while read -r user; do
      l_output2+=$'\n'"[⚠️[REPROVADO]]: Nome de usuário duplicado: \"$user\""
   done

   if [ -z "$l_output2" ]; then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum nome de usuário duplicado foi encontrado."
   fi

   printf '\n- Resultado da Auditoria (%s):\n%s\n' "$label" "${l_output2:-$l_output}"
}

check_7_2_7() {
   local label="295"
   local l_output="" l_output2=""

   cut -d: -f1 /etc/group | sort | uniq -d | while read -r group; do
      l_output2+=$'\n'"[⚠️[REPROVADO]]: Nome de grupo duplicado: \"$group\""
   done

   if [ -z "$l_output2" ]; then
      l_output+=$'\n'"✅ [APROVADO]: Nenhum nome de grupo duplicado foi encontrado."
   fi

   printf '\n- Resultado da Auditoria (%s):\n%s\n' "$label" "${l_output2:-$l_output}"
}

# === Execução sequencial ===
check_7_2_1
check_7_2_2
check_7_2_3
check_7_2_4
check_7_2_5
check_7_2_6
check_7_2_7

exit 0