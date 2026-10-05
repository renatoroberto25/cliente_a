#!/usr/bin/env bash
echo "[226] Corrigir arquivos sem dono (unowned)"

DATA=$(date +%Y%m%d%H%M%S)
TMP_LOG="/tmp/unowned_$DATA.txt"

# Localiza arquivos sem dono
df --local -P | awk 'NR!=1 {print $6}' | xargs -I{} find '{}' -xdev -nouser 2>/dev/null > "$TMP_LOG"

COUNT=$(wc -l < "$TMP_LOG")
if [ "$COUNT" -eq 0 ]; then
  echo "✅ Nenhum arquivo sem dono encontrado"
else
  echo "⚠️ $COUNT arquivos sem dono encontrados — atribuindo ownership a root com backup"
  while read -r file; do
    [ -f "$file" ] || continue
    cp -p "$file" "${file}.bak.$DATA"
    chown root "$file"
  done < "$TMP_LOG"
  echo "✔ Ownership corrigido — lista salva em $TMP_LOG"
fi
echo "[ℹ️ FIM]"