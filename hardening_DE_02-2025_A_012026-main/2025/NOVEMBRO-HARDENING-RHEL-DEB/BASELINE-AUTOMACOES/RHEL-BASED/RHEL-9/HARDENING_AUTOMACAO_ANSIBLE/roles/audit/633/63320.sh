#!/usr/bin/env bash
echo "264 Ensure the audit configuration is immutable"

echo "Verificando se a configuração do audit é imutável no disco..."
IMMUTABLE_FOUND=$(grep -Ph -- '^\h*-e\h+2\b' /etc/audit/rules.d/*.rules 2>/dev/null | tail -1)

if [[ "$IMMUTABLE_FOUND" == "-e 2" ]]; then
echo "✅ [APROVADO]: Configuração '-e 2' encontrada:"
echo "$IMMUTABLE_FOUND"
else
echo "⚠️[REPROVADO]: Configuração '-e 2' não encontrada nos arquivos de regras."
fi