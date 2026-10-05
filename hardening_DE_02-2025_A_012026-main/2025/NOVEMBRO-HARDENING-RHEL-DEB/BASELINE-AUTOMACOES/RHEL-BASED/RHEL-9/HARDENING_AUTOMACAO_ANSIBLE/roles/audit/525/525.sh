#!/usr/bin/env bash

echo " [169] Verificar se a reautenticação está habilitada no sudo"

if grep -Erq '^\s*[^#].*\!authenticate\b' /etc/sudoers /etc/sudoers.d 2>/dev/null; then
  echo "⚠️ [REPROVADO] Encontradas entradas com '!authenticate':"
  grep -Er '^\s*[^#].*\!authenticate\b' /etc/sudoers /etc/sudoers.d 2>/dev/null
else
  echo "✅ [APROVADO] Nenhuma entrada com '!authenticate' encontrada"
fi

echo "⚠️ Remover '!authenticate' pode afetar automações ou serviços com escalonamento sem senha"
echo "⚠️ Valide manualmente antes de aplicar a remediação"

echo -e "\n✅ Auditoria finalizada"
exit 0