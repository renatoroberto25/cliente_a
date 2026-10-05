#!/usr/bin/env bash

echo " [167] Corrigir configuração 'Defaults logfile' no sudo"

arq="/etc/sudoers"
bk="${arq}.bak.$(date +%Y%m%d%H%M%S)"
linha='Defaults logfile="/var/log/sudo.log"'

if grep -Fxq "$linha" "$arq"; then
  echo "✅ [OK] '$linha' já está presente em $arq"
else
  cp -p "$arq" "$bk"
  echo -e "\n# Adicionado por remediação [167]\n$linha" >> "$arq"
  echo "✅ Linha adicionada em $arq (backup: $bk)"
fi

echo -e "\n✅ Remediação finalizada"
exit 0