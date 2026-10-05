#!/usr/bin/env bash
echo "262 Ensure successful and unsuccessful attempts to use the usermod command are collected"

# Verificar configuração de regras de auditoria no disco
echo "Verificando regras de auditoria no disco..."
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
if [[ -n "$UID_MIN" ]]; then
  FILES_TO_CHECK=()
  [[ -f /etc/audit/audit.rules ]] && FILES_TO_CHECK+=("/etc/audit/audit.rules")
  [[ -d /etc/audit/rules.d ]] && FILES_TO_CHECK+=("/etc/audit/rules.d/"*.rules)

  USERMOD_RULES=$(grep -H "/usr/sbin/usermod" "${FILES_TO_CHECK[@]}" 2>/dev/null | \
    grep -E "\-a\s+always,exit" | \
    grep -E "\-F\s+perm=x" | \
    grep -E "\-F\s+auid>=${UID_MIN}" | \
    grep -E "key=\S+|\-k\s+\S+")

  if [[ -n "$USERMOD_RULES" ]]; then
echo "✅ [APROVADO]: Regras de auditoria encontradas no disco:"
echo "$USERMOD_RULES"
  else
echo "⚠️[REPROVADO]: Nenhuma regra encontrada no disco."
  fi
else
echo "ERROR: Variável 'UID_MIN' não está definida."
fi

echo ""
echo "Verificando regras de auditoria carregadas (runtime)..."

if [[ -n "$UID_MIN" ]]; then
  LOADED_RULES=$(auditctl -l 2>/dev/null | \
    grep -E "\-a\s+always,exit" | \
    grep -E "\-F\s+perm=x" | \
    grep -E "\-F\s+auid>=${UID_MIN}" | \
    grep -E "\-F\s+path=/usr/sbin/usermod" | \
    grep -E "key=\S+|\-k\s+\S+")

  if [[ -n "$LOADED_RULES" ]]; then
echo "✅ [APROVADO]: Regras carregadas:"
echo "$LOADED_RULES"
  else
echo "⚠️[REPROVADO]: Nenhuma regra carregada."
  fi
else
echo "ERROR: Variável 'UID_MIN' não está definida."
fi