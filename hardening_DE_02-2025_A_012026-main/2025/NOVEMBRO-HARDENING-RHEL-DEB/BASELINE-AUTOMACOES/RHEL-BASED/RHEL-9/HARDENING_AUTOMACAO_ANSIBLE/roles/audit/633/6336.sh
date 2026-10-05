#!/usr/bin/env bash
echo "250 Ensure use of privileged commands are collected"

# Lista de arquivos onde as regras podem estar configuradas
files_to_check=()
[[ -f /etc/audit/audit.rules ]] && files_to_check+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && files_to_check+=("/etc/audit/rules.d/"*.rules)

# Identifica comandos privilegiados (SUID/SGID)
PRIV_CMDS=$(find / -xdev -perm /6000 -type f 2>/dev/null)

# Verificação no disco
DISK_RULES=$(grep -hFf <(echo "$PRIV_CMDS") "${files_to_check[@]}" 2>/dev/null)
if [[ -n "$DISK_RULES" ]]; then
echo "✅ [APROVADO]: Regras de auditoria para comandos privilegiados encontradas no disco."
else
echo "⚠️[REPROVADO]: Nenhuma regra de auditoria para comandos privilegiados encontrada no disco."
fi

# Verificação em tempo de execução
LOADED_RULES=$(auditctl -l 2>/dev/null | grep -Ff <(echo "$PRIV_CMDS"))
if [[ -n "$LOADED_RULES" ]]; then
echo "✅ [APROVADO]: Regras de auditoria para comandos privilegiados carregadas no sistema."
else
echo "⚠️[REPROVADO]: Nenhuma regra de auditoria para comandos privilegiados carregada."
fi