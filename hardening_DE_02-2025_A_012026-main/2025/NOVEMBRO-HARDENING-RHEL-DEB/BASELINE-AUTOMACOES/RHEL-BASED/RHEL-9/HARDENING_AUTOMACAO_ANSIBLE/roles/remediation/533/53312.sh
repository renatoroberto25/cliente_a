#!/usr/bin/env bash

echo -e "\n[181] Configurar tempo de desbloqueio de senha (unlock_time >= 900 ou 0)"

arquivo="/etc/security/faillock.conf"
parametro="unlock_time"
valor_desejado=900

if [[ ! -f "$arquivo" ]]; then
  echo "❗ Arquivo $arquivo não encontrado"
  exit 0
fi

# Backup
cp "$arquivo" "${arquivo}.bak.$(date +%Y%m%d%H%M%S)" && echo "🗂️ Backup criado: ${arquivo}.bak.*"

# Verifica e ajusta o parâmetro
if grep -q "^$parametro\s*=" "$arquivo"; then
  sed -i "s/^$parametro\s*=.*/$parametro = $valor_desejado/" "$arquivo"
  echo "✅ '$parametro' ajustado para $valor_desejado em $arquivo"
else
  echo "$parametro = $valor_desejado" >> "$arquivo"
  echo "✅ '$parametro' adicionado ao $arquivo"
fi

# Remoção de unlock_time com valor inadequado nos PAMs
for pamfile in /etc/pam.d/system-auth /etc/pam.d/password-auth; do
  if grep -qE 'unlock_time\s*=\s*([1-9]|[1-9][0-9]|[1-8][0-9]{2})\b' "$pamfile"; then
    cp "$pamfile" "${pamfile}.bak.$(date +%Y%m%d%H%M%S)" && echo "🗂️ Backup criado: ${pamfile}.bak.*"
    sed -ri 's/(^\s*auth\s+(requisite|required|sufficient)\s+pam_faillock\.so.*)(\s+unlock_time\s*=\s*\S+)(.*$)/\1\4/' "$pamfile"
    echo "✅ 'unlock_time' removido de $pamfile"
  fi
done