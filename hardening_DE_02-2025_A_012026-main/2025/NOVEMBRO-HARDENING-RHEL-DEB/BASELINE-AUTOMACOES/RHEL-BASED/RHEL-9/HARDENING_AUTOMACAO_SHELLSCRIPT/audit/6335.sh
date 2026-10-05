#!/usr/bin/env bash
echo "249 Ensure events that modify the system's network environment are collected"

# Lista de arquivos onde as regras podem estar configuradas
files_to_check=()
[[ -f /etc/audit/audit.rules ]] && files_to_check+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && files_to_check+=("/etc/audit/rules.d/"*.rules)

# Verificação de regras persistentes no disco (configurações gravadas)
# - Verifica se existem syscalls para sethostname ou setdomainname
DISK_SYSCALLS=$(grep -E '^-a always,exit.*-F arch=b(32|64).*-(S|syscall) (sethostname|setdomainname)' "${files_to_check[@]}" 2>/dev/null)

# - Verifica se os arquivos de rede estão sendo monitorados com permissão wa
DISK_FILES=$(grep -E '^-w +(\/etc\/issue|\/etc\/issue.net|\/etc\/hosts|\/etc\/sysconfig\/network|\/etc\/hostname|\/etc\/NetworkManager).* -p *wa.*-(k|key) *[[:alnum:]_-]+' "${files_to_check[@]}" 2>/dev/null)

if [[ -n "$DISK_SYSCALLS" && -n "$DISK_FILES" ]]; then
echo "✅ [APROVADO]: Regras de auditoria encontradas no disco:"
echo "$DISK_SYSCALLS"
echo "$DISK_FILES"
else
echo "⚠️[REPROVADO]: Regras de auditoria ausentes ou incompletas no disco."
    [[ -z "$DISK_SYSCALLS" ]] && echo "❌ Faltando syscall: sethostname/setdomainname"
    [[ -z "$DISK_FILES" ]] && echo "❌ Faltando file watches: arquivos de rede"
fi

# Verificação de regras carregadas em tempo de execução
LOADED_SYSCALLS=$(auditctl -l 2>/dev/null | grep -E '^-a always,exit.*-F arch=b(32|64).*-(S|syscall) (sethostname|setdomainname)')
LOADED_FILES=$(auditctl -l 2>/dev/null | grep -E '^-w +(\/etc\/issue|\/etc\/issue.net|\/etc\/hosts|\/etc\/sysconfig\/network|\/etc\/hostname|\/etc\/NetworkManager).* -p *wa.*-(k|key) *[[:alnum:]_-]+')

if [[ -n "$LOADED_SYSCALLS" && -n "$LOADED_FILES" ]]; then
echo "✅ [APROVADO]: Regras de auditoria carregadas:"
echo "$LOADED_SYSCALLS"
echo "$LOADED_FILES"
else
echo "⚠️[REPROVADO]: Regras de auditoria carregadas ausentes ou incompletas."
    [[ -z "$LOADED_SYSCALLS" ]] && echo "❌ Faltando syscall: sethostname/setdomainname"
    [[ -z "$LOADED_FILES" ]] && echo "❌ Faltando file watches: arquivos de rede"
fi