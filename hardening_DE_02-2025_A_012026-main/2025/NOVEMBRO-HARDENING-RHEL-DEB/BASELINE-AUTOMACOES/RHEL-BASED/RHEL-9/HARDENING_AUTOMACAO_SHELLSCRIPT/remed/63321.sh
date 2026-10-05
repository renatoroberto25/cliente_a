#!/usr/bin/env bash
echo "265 Ensure the running and on disk configuration is the same"

echo "Carregando as regras persistentes com augenrules..."
augenrules --load && echo "✅ Regras carregadas com sucesso"

# Verifica se o audit está em modo imutável
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
  echo "⚠️ O audit está em modo imutável. Reboot necessário para aplicar as regras."
else
  echo "✅ Audit não está em modo imutável. As regras foram aplicadas imediatamente."
fi