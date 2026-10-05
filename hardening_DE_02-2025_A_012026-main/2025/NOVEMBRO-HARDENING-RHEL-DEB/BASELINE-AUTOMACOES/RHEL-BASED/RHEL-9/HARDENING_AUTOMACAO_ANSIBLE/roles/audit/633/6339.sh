#!/usr/bin/env bash
echo "253 Ensure discretionary access control permission modification events are collected"

# Obtemos o UID mínimo do sistema
UID_MIN=$(grep -E '^\s*UID_MIN' /etc/login.defs | awk '{print $2}')

if [[ -z "$UID_MIN" ]]; then
echo "❌ ERRO: UID_MIN não encontrado em /etc/login.defs"
  exit 1
fi

echo "Verificando regras de auditoria no disco..."

# Lista de syscalls que devem estar sendo auditadas
SYS_CALLS="chmod|fchmod|fchmodat|chown|fchown|fchownat|lchown|setxattr|lsetxattr|fsetxattr|removexattr|lremovexattr|fremovexattr"

# Verifica se alguma linha em /etc/audit/rules.d/* contém todas as condições esperadas
DISK_CHECK=$(grep -E "^-a always,exit" /etc/audit/rules.d/*.rules 2>/dev/null | \
  grep -E "arch=b(32|64)" | \
  grep -E "auid>=$UID_MIN" | \
  grep -E "auid!=unset" | \
  grep -E "key=perm_mod" | \
  grep -E "$SYS_CALLS")

if [[ -n "$DISK_CHECK" ]]; then
echo "✅ [APROVADO]: Regras de auditoria encontradas no disco:"
echo "$DISK_CHECK"
else
echo "⚠️[REPROVADO]: Nenhuma regra válida encontrada no disco."
fi

echo ""
echo "Verificando regras de auditoria carregadas (runtime)..."

# Verifica regras ativas no runtime via auditctl (ajustado para aceitar unset ou -1)
RUNTIME_CHECK=$(auditctl -l 2>/dev/null | \
  grep -E "arch=b(32|64)" | \
  grep -E "auid>=$UID_MIN" | \
  grep -E "auid!=(unset|-1)" | \
  grep -E "key=perm_mod" | \
  grep -E "$SYS_CALLS")

if [[ -n "$RUNTIME_CHECK" ]]; then
echo "✅ [APROVADO]: Regras de auditoria carregadas:"
echo "$RUNTIME_CHECK"
else
echo "⚠️[REPROVADO]: Nenhuma regra válida carregada."
fi