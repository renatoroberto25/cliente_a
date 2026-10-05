#!/usr/bin/env bash
echo "245 Ensure changes to system administration scope (sudoers) is collected"

# Define arquivos a verificar (só se existirem)
files_to_check=()
[[ -f /etc/audit/audit.rules ]] && files_to_check+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && files_to_check+=("/etc/audit/rules.d/"*.rules)

if grep -Eq '^-w\s+/etc/sudoers(\.d)?\s+-p\s*wa\s+(-k|key=)' "${files_to_check[@]}" 2>/dev/null; then
echo "✅ [APROVADO]: Regra de auditoria para /etc/sudoers ou /etc/sudoers.d encontrada com -p wa e chave definida"
else
echo "⚠️[REPROVADO]: Regra de auditoria para /etc/sudoers ou /etc/sudoers.d NÃO encontrada ou está incompleta"
fi