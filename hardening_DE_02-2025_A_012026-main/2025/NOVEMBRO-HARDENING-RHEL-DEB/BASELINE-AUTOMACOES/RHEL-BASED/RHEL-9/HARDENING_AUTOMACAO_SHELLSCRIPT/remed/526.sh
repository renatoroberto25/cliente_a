#!/usr/bin/env bash

echo " [170] Corrigir timestamp_timeout do sudo (valor máximo: 5 minutos)"

data=$(date +%Y%m%d%H%M%S)
alterado=0

timeout=$(grep -Eo 'timestamp_timeout=[0-9]+' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | cut -d= -f2 | sort -nr | head -n1)

if [ -n "$timeout" ] && [ "$timeout" -gt 5 ]; then
  echo "⚠️ Valor encontrado: timestamp_timeout=$timeout (acima de 5). Corrigindo..."

  while IFS= read -r -d '' arq; do
    if grep -q 'timestamp_timeout=' "$arq"; then
      cp -p "$arq" "$arq.bak.$data"
      sed -i 's/timestamp_timeout=[0-9]\+/timestamp_timeout=5/g' "$arq"
      echo "✅ Corrigido em $arq (backup: $arq.bak.$data)"
      alterado=1
    fi
  done < <(find /etc/sudoers /etc/sudoers.d -type f -print0 2>/dev/null)
else
  echo "✅ Nenhuma configuração incorreta encontrada"
fi

echo -e "\n✅ Remediação finalizada"
exit 0