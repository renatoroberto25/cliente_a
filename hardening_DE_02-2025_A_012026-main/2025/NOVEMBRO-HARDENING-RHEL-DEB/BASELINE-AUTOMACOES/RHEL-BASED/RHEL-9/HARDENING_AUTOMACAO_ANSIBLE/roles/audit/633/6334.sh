#!/usr/bin/env bash
echo "248 Ensure events that modify date and time information are collected"

# Arquivos a verificar
files_to_check=()
[[ -f /etc/audit/audit.rules ]] && files_to_check+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && files_to_check+=("/etc/audit/rules.d/"*.rules)

# Verificação no disco
DISK_SYSCALLS=$(grep -E '^-a always,exit.*-F arch=b(32|64).*-(S|syscall) (adjtimex|settimeofday|clock_settime)' "${files_to_check[@]}" 2>/dev/null)
DISK_FILES=$(grep -E '^-w +/etc/localtime +.*-p *wa.*-(k|key) *[[:alnum:]_-]+' "${files_to_check[@]}" 2>/dev/null)

if [[ -n "$DISK_SYSCALLS" && -n "$DISK_FILES" ]]; then
echo "✅ [APROVADO]: Regras de auditoria encontradas no disco:"
echo "$DISK_SYSCALLS"
echo "$DISK_FILES"
else
echo "⚠️[REPROVADO]: Regras de auditoria ausentes ou incompletas no disco."
    [[ -z "$DISK_SYSCALLS" ]] && echo "❌ Faltando syscall: adjtimex/settimeofday/clock_settime"
    [[ -z "$DISK_FILES" ]] && echo "❌ Faltando file watch: /etc/localtime"
fi

# Verificação em tempo de execução
LOADED_SYSCALLS=$(auditctl -l 2>/dev/null | grep -E '^-a always,exit.*-F arch=b(32|64).*-(S|syscall) (adjtimex|settimeofday|clock_settime)')
LOADED_FILES=$(auditctl -l 2>/dev/null | grep -E '^-w +/etc/localtime +.*-p *wa.*-(k|key) *[[:alnum:]_-]+')

if [[ -n "$LOADED_SYSCALLS" && -n "$LOADED_FILES" ]]; then
echo "✅ [APROVADO]: Regras de auditoria carregadas:"
echo "$LOADED_SYSCALLS"
echo "$LOADED_FILES"
else
echo "⚠️[REPROVADO]: Regras de auditoria carregadas ausentes ou incompletas."
    [[ -z "$LOADED_SYSCALLS" ]] && echo "❌ Faltando syscall: adjtimex/settimeofday/clock_settime"
    [[ -z "$LOADED_FILES" ]] && echo "❌ Faltando file watch: /etc/localtime"
fi