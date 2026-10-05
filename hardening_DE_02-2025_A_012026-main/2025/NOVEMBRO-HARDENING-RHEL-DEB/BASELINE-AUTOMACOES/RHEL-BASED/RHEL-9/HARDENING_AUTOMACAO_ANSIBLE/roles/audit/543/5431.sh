#!/usr/bin/env bash
echo "[211] Verificar se '/nologin' está listado em /etc/shells"
echo "--- Iniciando verificação do arquivo /etc/shells ---"

if grep -Pq '^\h*([^#\n\r]+)?/nologin\b' /etc/shells; then
  echo "⚠️ [REPROVADO]: '/nologin' está presente em /etc/shells"
else
  echo "✅ [APROVADO]: Nenhuma entrada '/nologin' encontrada em /etc/shells"
fi

echo "✅ Auditoria finalizada"
exit 0