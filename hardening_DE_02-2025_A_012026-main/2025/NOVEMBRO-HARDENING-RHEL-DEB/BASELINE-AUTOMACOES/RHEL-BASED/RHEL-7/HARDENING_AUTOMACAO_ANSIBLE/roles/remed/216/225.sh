#!/usr/bin/env bash
echo "[225] Remover permissões world-writable (o+w)"

DATA=$(date +%Y%m%d%H%M%S)
TMP_LOG="/tmp/world_writable_$DATA.txt"

# Identifica arquivos world-writable
df --local -P | awk 'NR!=1 {print $6}' | xargs -I{} find '{}' -xdev -type f -perm -0002 2>/dev/null > "$TMP_LOG"

COUNT=$(wc -l < "$TMP_LOG")
if [ "$COUNT" -eq 0 ]; then
  echo "✅ Nenhum arquivo world-writable encontrado"
else
  echo "⚠️ $COUNT arquivos encontrados — removendo bit 'o+w' com backup"
  while read -r file; do
    [ -f "$file" ] || continue
    cp -p "$file" "${file}.bak.$DATA"
    chmod o-w "$file"
  done < "$TMP_LOG"
  echo "✔ Permissões ajustadas — lista salva em $TMP_LOG"
fi
echo "[ℹ️ FIM]"