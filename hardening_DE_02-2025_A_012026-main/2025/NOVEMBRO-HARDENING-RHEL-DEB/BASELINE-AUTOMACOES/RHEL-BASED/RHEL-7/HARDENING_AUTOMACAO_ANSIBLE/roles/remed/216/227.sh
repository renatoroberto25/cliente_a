#!/usr/bin/env bash
echo "[227] Corrigir arquivos sem grupo (ungrouped)"

DATA=$(date +%Y%m%d%H%M%S)
TMP_LOG="/tmp/ungrouped_$DATA.txt"

# Localiza arquivos sem grupo
df --local -P | awk 'NR!=1 {print $6}' | xargs -I{} find '{}' -xdev -nogroup 2>/dev/null > "$TMP_LOG"

COUNT=$(wc -l < "$TMP_LOG")
if [ "$COUNT" -eq 0 ]; then
  echo "✅ Nenhum arquivo sem grupo encontrado"
else
  echo "⚠️ $COUNT arquivos sem grupo encontrados — atribuindo grupo root com backup"
  while read -r file; do
    [ -f "$file" ] || continue
    cp -p "$file" "${file}.bak.$DATA"
    chgrp root "$file"
  done < "$TMP_LOG"
  echo "✔ Grupo corrigido — lista salva em $TMP_LOG"
fi
echo "[ℹ️ FIM]"