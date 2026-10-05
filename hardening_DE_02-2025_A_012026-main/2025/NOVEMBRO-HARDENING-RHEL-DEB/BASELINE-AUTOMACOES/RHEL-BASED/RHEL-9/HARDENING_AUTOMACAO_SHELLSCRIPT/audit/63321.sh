#!/usr/bin/env bash
echo "265 Ensure the running and on disk configuration is the same"

echo "Verificando se a configuração em disco e em execução estão sincronizadas..."
if augenrules --check 2>&1 | grep -q "No change"; then
echo "✅ [APROVADO]: Configuração em disco e em execução estão alinhadas."
else
echo "⚠️[REPROVADO]: Divergência entre a configuração em disco e a carregada."
  augenrules --check
fi