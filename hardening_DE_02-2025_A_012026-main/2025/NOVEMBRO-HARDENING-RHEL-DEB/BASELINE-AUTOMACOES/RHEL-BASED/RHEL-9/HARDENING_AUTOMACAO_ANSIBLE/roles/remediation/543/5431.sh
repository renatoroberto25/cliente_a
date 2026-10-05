#!/usr/bin/env bash
echo "[211] Remover '/nologin' do arquivo /etc/shells se presente"
echo "--- Verificando /etc/shells ---"

arq="/etc/shells"
bk="${arq}.bak.$(date +%Y%m%d%H%M%S)"
cp -p "$arq" "$bk"

if grep -Pq '^\h*([^#\n\r]+)?/nologin\b' "$arq"; then
  sed -i -E '/^\h*([^#\n\r]+)?\/nologin\b/d' "$arq"
  echo "✅ '/nologin' removido do arquivo (backup: $bk)"
else
  echo "✅ Nenhuma entrada '/nologin' encontrada em $arq"
fi

exit 0