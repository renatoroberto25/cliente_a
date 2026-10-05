#!/usr/bin/env bash
echo "263 Ensure kernel module loading, unloading and modification is collected"

# Verificar regras de auditoria no disco
echo "Verificando regras de auditoria no disco..."
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

if [[ -n "$UID_MIN" ]]; then
  FILES_TO_CHECK=()
  [[ -f /etc/audit/audit.rules ]] && FILES_TO_CHECK+=("/etc/audit/audit.rules")
  [[ -d /etc/audit/rules.d ]] && FILES_TO_CHECK+=("/etc/audit/rules.d/"*.rules)

  RULES_DISK=$(grep -H "kernel_modules" "${FILES_TO_CHECK[@]}" 2>/dev/null | \
    grep -E "\-a\s+always,exit" | \
    grep -E "\-F\s+arch=b(32|64)" | \
    grep -E "\-F\s+auid>=$UID_MIN" | \
    grep -E "\-F\s+auid!=(unset|-1|4294967295)" | \
    grep -E "\-S\s+(init_module|finit_module|delete_module|create_module|query_module)|\-F\s+path=/usr/bin/kmod" | \
    grep -E "key=\S+|\-k\s+\S+")

  if [[ -n "$RULES_DISK" ]]; then
echo "✅ [APROVADO]: Regras encontradas no disco:"
echo "$RULES_DISK"
  else
echo "⚠️[REPROVADO]: Nenhuma regra válida encontrada no disco."
  fi
else
echo "ERROR: Variável 'UID_MIN' não está definida."
fi

echo ""
echo "Verificando regras de auditoria carregadas (runtime)..."

if [[ -n "$UID_MIN" ]]; then
  RULES_RUNTIME=$(auditctl -l 2>/dev/null | \
    grep -E "\-a\s+always,exit" | \
    grep -E "\-F\s+arch=b(32|64)" | \
    grep -E "\-F\s+auid>=$UID_MIN" | \
    grep -E "\-F\s+auid!=(unset|-1|4294967295)" | \
    grep -E "\-S\s+(init_module|finit_module|delete_module|create_module|query_module)|\-F\s+path=/usr/bin/kmod" | \
    grep -E "key=\S+|\-k\s+\S+")

  if [[ -n "$RULES_RUNTIME" ]]; then
echo "✅ [APROVADO]: Regras carregadas:"
echo "$RULES_RUNTIME"
  else
echo "⚠️[REPROVADO]: Nenhuma regra válida carregada."
  fi
else
echo "ERROR: Variável 'UID_MIN' não está definida."
fi