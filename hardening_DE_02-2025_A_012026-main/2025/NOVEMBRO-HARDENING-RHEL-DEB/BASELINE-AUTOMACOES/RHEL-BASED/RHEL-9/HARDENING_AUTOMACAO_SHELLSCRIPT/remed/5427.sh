#!/usr/bin/env bash

echo -e "\n[209] Remediar contas de sistema com shell válido"
echo "--- Iniciando correção das contas de serviço ---"

# --- Coleta shells válidos (exceto nologin/false) ---
l_valid_shells=$(awk '!/nologin|false/ {print $0}' /etc/shells | paste -sd '|')
uid_min=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
[ -z "$uid_min" ] && uid_min=1000

# --- Busca usuários de sistema com shell considerado válido ---
awk -v pat="^(${l_valid_shells})$" -v uid_min="$uid_min" -F: '
  ($1 !~ /^(root|halt|sync|shutdown|nfsnobody)$/ && ($3 < uid_min || $3 == 65534) && $NF ~ pat) {
    print $1
  }
' /etc/passwd | while read -r user; do
  if usermod -s /sbin/nologin "$user"; then
    echo "✅ Shell da conta \"$user\" alterado para /sbin/nologin"
  else
    echo "❗ Erro ao modificar shell de \"$user\""
  fi
done

echo "✅ Correção concluída."
exit 0