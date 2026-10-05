#!/usr/bin/env bash

echo -e "\n[210] Bloquear contas com shell inválido"
echo "--- Iniciando bloqueio de contas com shell inválido ---"

l_valid_shells="^($(awk -F/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' -))$"
contas_bloqueadas=0

while IFS= read -r l_user; do
  if passwd -S "$l_user" | awk '$2 !~ /^L/' >/dev/null; then
    usermod -L "$l_user" && echo "✅ Conta \"$l_user\" bloqueada"
    ((contas_bloqueadas++))
  fi
done < <(awk -v pat="$l_valid_shells" -F: '($1 != "root" && $(NF) !~ pat) {print $1}' /etc/passwd)

if [[ "$contas_bloqueadas" -eq 0 ]]; then
  echo "✅ Nenhuma conta com shell inválido precisava de bloqueio"
fi

exit 0