#!/usr/bin/env bash
echo "[296] Corrigir diretórios home de usuários interativos locais"

l_mask="0027"
l_max="$(printf '%o' $((0777 & ~$l_mask)) )"
l_output=""

# Obter shells válidos (exclui nologin/false)
valid_shells="^($(awk -F/ '$NF != "nologin" && $NF != "false" {print}' /etc/shells | sed -E 's|/|\\/|g' | paste -sd '|' -))$"

# Coletar usuários interativos e seus homes
while IFS=: read -r user _ _ _ _ home shell; do
  [[ "$shell" =~ $valid_shells ]] || continue
  [[ -d "$home" ]] || {
    l_output+="\n⚠️ [AVISO]: Diretório home \"$home\" de \"$user\" não existe."
    continue
  }

  # Validações extras de segurança
  [[ "$home" == "/" || -z "$home" ]] && continue

  # Checa e ajusta propriedade
  current_owner=$(stat -Lc '%U' "$home" 2>/dev/null)
  if [[ "$current_owner" != "$user" ]]; then
    if chown "$user" "$home" 2>/dev/null; then
      l_output+="\n✅ Propriedade de \"$home\" corrigida para \"$user\"."
    else
      l_output+="\n❌ Falha ao corrigir propriedade de \"$home\"."
    fi
  fi

  # Checa e ajusta permissões
  current_perm=$(stat -Lc '%a' "$home" 2>/dev/null)
  if (( 8#$current_perm & 8#$l_mask )); then
    if chmod g-w,o-rwx "$home" 2>/dev/null; then
      l_output+="\n✅ Permissões de \"$home\" ajustadas (máx: $l_max)."
    else
      l_output+="\n❌ Falha ao ajustar permissões de \"$home\"."
    fi
  fi
done < /etc/passwd

if [[ -z "$l_output" ]]; then
  echo "✅ Todos os diretórios home já estavam em conformidade."
else
  echo -e "$l_output"
fi

exit 0