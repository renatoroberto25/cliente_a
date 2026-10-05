#!/usr/bin/env bash

echo " [169] Remover diretivas '!authenticate' do sudo"
echo " ⚠️ Essa remediação pode impactar serviços e automações. Validar antes de aplicar."

data=$(date +%Y%m%d%H%M%S)
alterado=0

for arq in $(find /etc/sudoers /etc/sudoers.d -type f 2>/dev/null); do
  if grep -q '^[^#]*Defaults.*!authenticate' "$arq"; then
    cp -p "$arq" "$arq.bak.$data"
    sed -i 's/\(Defaults[^#]*\)!authenticate/\1/g' "$arq"
    sed -i '/^Defaults:[^a-zA-Z0-9]*$/d' "$arq"
    sed -i '/^Defaults:[^ ]*$/d' "$arq"
    echo "✅ '!authenticate' removido de $arq (backup: $arq.bak.$data)"
    alterado=1
  fi
done

if [ "$alterado" -eq 0 ]; then
  echo "✅ Nenhuma diretiva '!authenticate' ativa encontrada"
else
  if visudo -c >/dev/null 2>&1; then
    echo "✅ sudoers válido após a modificação"
  else
    echo "❌ Erro de sintaxe em sudoers! Verifique manualmente"
  fi
fi

echo -e "\n✅ Remediação finalizada"
exit 0