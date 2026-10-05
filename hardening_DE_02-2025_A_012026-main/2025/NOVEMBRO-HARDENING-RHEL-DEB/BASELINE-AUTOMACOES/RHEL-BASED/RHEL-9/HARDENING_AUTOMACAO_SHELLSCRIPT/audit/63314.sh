#!/usr/bin/env bash
echo "258 Ensure events that modify the system's Mandatory Access Controls are collected"

# Verificar configuração de regras de auditoria no disco
echo "Verificando regras de auditoria no disco..."
FILES_TO_CHECK=()
[[ -f /etc/audit/audit.rules ]] && FILES_TO_CHECK+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && FILES_TO_CHECK+=("/etc/audit/rules.d/"*.rules)

MAC_RULES=$(grep -H "/etc/selinux" "${FILES_TO_CHECK[@]}" 2>/dev/null | \
  grep -E "\-w\s+/etc/selinux" | \
  grep -E "\-p\s+wa" | \
  grep -E "key=\S+|\-k\s+\S+")

if [[ -n "$MAC_RULES" ]]; then
echo "✅ [APROVADO]: Regras de auditoria encontradas no disco:"
echo "$MAC_RULES"
else
echo "⚠️[REPROVADO]: Nenhuma regra encontrada no disco."
fi

echo ""
echo "Verificando regras de auditoria carregadas (runtime)..."

LOADED_RULES=$(auditctl -l 2>/dev/null | \
  grep -E "\-w\s+/etc/selinux" | \
  grep -E "\-p\s+wa" | \
  grep -E "key=\S+|\-k\s+\S+")

if [[ -n "$LOADED_RULES" ]]; then
echo "✅ [APROVADO]: Regras carregadas:"
echo "$LOADED_RULES"
else
echo "⚠️[REPROVADO]: Nenhuma regra carregada."
fi