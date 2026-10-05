#!/usr/bin/env bash

echo " [166] Verificar se o sudo está configurado para usar pseudo terminal (PTY)"

achou=0
falhou=0

while IFS= read -r -d '' arq; do
  if grep -Eq '^\s*Defaults\s+use_pty\b' "$arq"; then
    echo "✅ [APROVADO] $arq contém 'Defaults use_pty'"
    achou=$((achou + 1))
  else
    echo "⚠️ [REPROVADO] $arq não contém 'Defaults use_pty'"
    grep -E '^\s*Defaults\s+!pty\b' "$arq" && echo "⚠️ Atenção: uso de '!pty' encontrado"
    falhou=$((falhou + 1))
  fi
done < <(find /etc/sudoers /etc/sudoers.d -type f -print0 2>/dev/null)

if [ "$achou" -eq 0 ]; then
  echo "⚠️ [REPROVADO] Nenhum arquivo sudo contém 'Defaults use_pty'"
fi

echo -e "\n✅ Auditoria finalizada"
exit 0