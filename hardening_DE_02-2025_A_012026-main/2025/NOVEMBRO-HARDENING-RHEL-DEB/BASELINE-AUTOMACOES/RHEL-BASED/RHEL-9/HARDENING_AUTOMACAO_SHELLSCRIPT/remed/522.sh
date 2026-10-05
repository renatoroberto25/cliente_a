#!/usr/bin/env bash

echo " [166] Corrigir configuração 'Defaults use_pty' no sudo"

data=$(date +%Y%m%d%H%M%S)

while IFS= read -r -d '' arq; do
  if grep -Eq '^\s*Defaults\s+use_pty\b' "$arq"; then
    echo "✅ [OK] '$arq' já contém 'Defaults use_pty'"
  else
    cp -p "$arq" "$arq.bak.$data"
    echo -e "\n# Adicionado por remediação [166]\nDefaults use_pty" >> "$arq"
    echo "✅ Configuração adicionada a $arq (backup: $arq.bak.$data)"
  fi
done < <(find /etc/sudoers /etc/sudoers.d -type f -print0 2>/dev/null)

echo -e "\n✅ Remediação finalizada"
exit 0