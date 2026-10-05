#!/usr/bin/env bash

echo " Remediação - 277 Garantir que as permissões de /etc/passwd- estejam configuradas corretamente"

if [ -e /etc/passwd- ]; then
  echo "-> Corrigindo permissões e propriedade de /etc/passwd-..."
  chmod 644 /etc/passwd- && echo "✓ Permissões ajustadas para 644"
  chown root:root /etc/passwd- && echo "✓ Proprietário ajustado para root:root"
else
  echo "⚠️ O arquivo /etc/passwd- não foi encontrado."
fi