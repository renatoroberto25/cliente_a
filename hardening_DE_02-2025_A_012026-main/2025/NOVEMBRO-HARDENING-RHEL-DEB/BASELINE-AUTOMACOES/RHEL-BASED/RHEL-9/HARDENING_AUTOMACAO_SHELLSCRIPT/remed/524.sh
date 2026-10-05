#!/usr/bin/env bash

echo " [168] Remover configurações NOPASSWD do sudo (exige senha para escalonamento)"
echo " ⚠️ Essa remediação pode impactar automações e serviços. Validar antes de aplicar."

data=$(date +%Y%m%d%H%M%S)
alterado=0

for arq in $(find /etc/sudoers /etc/sudoers.d -type f 2>/dev/null); do
  if grep -q '^[^#].*NOPASSWD' "$arq"; then
    cp -p "$arq" "$arq.bak.$data"
    sed -i 's/NOPASSWD: *//g' "$arq"
    echo "✅ NOPASSWD removido de $arq (backup: $arq.bak.$data)"
    alterado=1
  fi
done

if [ "$alterado" -eq 0 ]; then
  echo "✅ Nenhuma configuração NOPASSWD ativa encontrada"
else
  if visudo -c >/dev/null 2>&1; then
    echo "✅ sudoers válido após a modificação"
  else
    echo "❌ Erro de sintaxe detectado em sudoers! Verifique manualmente"
  fi
fi

echo -e "\n✅ Remediação finalizada"
exit 0