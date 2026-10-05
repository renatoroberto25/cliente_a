#!/usr/bin/env bash

echo -e "\n[180] Configurar bloqueio após falhas de senha (deny <= 5)"

arquivo="/etc/security/faillock.conf"
parametro="deny"
valor_desejado=5

if [[ ! -f "$arquivo" ]]; then
  echo "❗ Arquivo $arquivo não encontrado"
  exit 0
fi

# Backup com timestamp
cp "$arquivo" "${arquivo}.bak.$(date +%Y%m%d%H%M%S)" && echo "🗂️ Backup criado: ${arquivo}.bak.*"

# Verifica e ajusta a configuração
if grep -q "^$parametro\s*=" "$arquivo"; then
  sed -i "s/^$parametro\s*=.*/$parametro = $valor_desejado/" "$arquivo"
  echo "✅ '$parametro' ajustado para $valor_desejado em $arquivo"
else
  echo "$parametro = $valor_desejado" >> "$arquivo"
  echo "✅ '$parametro' adicionado com valor $valor_desejado em $arquivo"
fi