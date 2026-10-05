#!/usr/bin/env bash
echo "251 Ensure unsuccessful file access attempts are collected"

# Obtém o UID mínimo a partir do /etc/login.defs
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

if [[ -z "$UID_MIN" ]]; then
echo "❌ ERRO: UID_MIN não encontrado em /etc/login.defs"
  exit 1
fi

files_to_check=()
[[ -f /etc/audit/audit.rules ]] && files_to_check+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && files_to_check+=("/etc/audit/rules.d/"*.rules)

echo "Verificando regras de auditoria no disco..."

# Verificação das regras no disco
DISK_RULES=$(grep -H "^-a always,exit" "${files_to_check[@]}" 2>/dev/null | \
  grep -E "arch=b(32|64)" | \
  grep -E "exit=-?(EACCES|EPERM)" | \
  grep -E "auid>=$UID_MIN" | \
  grep -E "auid!=(unset|-1)" | \
  grep -E "key=access|-k access")

if [[ -n "$DISK_RULES" ]]; then
echo "✅ [APROVADO]: Regras de auditoria encontradas no disco:"
echo "$DISK_RULES"
else
echo "⚠️[REPROVADO]: Regras de auditoria ausentes ou incompletas no disco."
fi

echo ""
echo "Verificando regras de auditoria carregadas (runtime)..."

# Verificação das regras carregadas
LOADED_RULES=$(auditctl -l 2>/dev/null | \
  grep -E "arch=b(32|64)" | \
  grep -E "exit=-?(EACCES|EPERM)" | \
  grep -E "auid>=$UID_MIN" | \
  grep -E "auid!=(unset|-1)" | \
  grep -E "key=access|-k access")

if [[ -n "$LOADED_RULES" ]]; then
echo "✅ [APROVADO]: Regras carregadas:"
echo "$LOADED_RULES"
else
echo "⚠️[REPROVADO]: Regras de auditoria carregadas ausentes ou incompletas."
fi