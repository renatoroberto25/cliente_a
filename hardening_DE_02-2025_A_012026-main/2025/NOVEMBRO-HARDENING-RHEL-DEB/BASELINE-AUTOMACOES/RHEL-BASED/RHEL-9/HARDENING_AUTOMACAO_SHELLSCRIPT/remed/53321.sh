#!/usr/bin/env bash

echo -e "\n[183 - 189] Reforço de políticas de senha – pwquality.conf"

arquivo="/etc/security/pwquality.conf"
bk="${arquivo}.bak.$(date +%Y%m%d%H%M%S)"
cp "$arquivo" "$bk" && echo "🗂️ Backup criado: $bk"

# Lista de parâmetros e valores esperados
declare -A parametros=(
  [difok]=2
  [minlen]=14
  [minclass]=4
  [maxrepeat]=3
  [maxsequence]=3
)

# Aplica os parâmetros padrão
for param in "${!parametros[@]}"; do
  valor="${parametros[$param]}"
  if grep -Pq "^\s*${param}\s*=" "$arquivo"; then
    sed -i "s/^\s*${param}\s*=.*/# $(grep -P "^\s*${param}\s*=" "$arquivo")/" "$arquivo"
  fi
  echo "${param} = ${valor}" >> "$arquivo"
  echo "✅ Parâmetro '${param}' ajustado para '${valor}'"
done

# dictcheck (deve estar ativado ou ausente)
if grep -Pq '^\s*dictcheck\s*=\s*0\b' "$arquivo"; then
  sed -i 's/^\s*dictcheck\s*=.*/# &/' "$arquivo"
  echo "✅ 'dictcheck = 0' comentado para reabilitar verificação de dicionário"
else
  echo "✅ 'dictcheck' já está habilitado ou ausente"
fi

# enforce_for_root (deve estar presente)
if grep -Pq '^\s*enforce_for_root\b' "$arquivo"; then
  echo "✅ 'enforce_for_root' já presente"
else
  echo -e "\n# Adicionado por script de remediação\nenforce_for_root" >> "$arquivo"
  echo "✅ 'enforce_for_root' adicionado"
fi