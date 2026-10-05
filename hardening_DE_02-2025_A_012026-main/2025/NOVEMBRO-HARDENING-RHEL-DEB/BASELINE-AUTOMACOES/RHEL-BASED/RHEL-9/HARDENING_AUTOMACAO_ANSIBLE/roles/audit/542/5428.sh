#!/usr/bin/env bash

echo -e "\n[210] Verificar se contas sem shell válido estão bloqueadas"
echo "--- Iniciando verificação de contas sem shell válido ---"

# Shells válidos (exclui nologin e false)
valid_shells=$(awk '!/nologin|false/ {print $1}' /etc/shells | paste -sd '|' -)
uid_min=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
[ -z "$uid_min" ] && uid_min=1000

awk -v valids="$valid_shells" -v uid_min="$uid_min" -F: '
($3 < uid_min && $1 != "root" && $7 !~ valids) { print $1 ":" $7 }
' /etc/passwd | while IFS=: read -r user shell; do
  status=$(passwd -S "$user" 2>/dev/null | awk '{print $2}')
  if [[ "$status" != L* ]]; then
    echo "⚠️ [REPROVADO]: Conta \"$user\" sem shell válido ($shell) e não está bloqueada"
  fi
done

echo "✅ Auditoria finalizada"
exit 0