#!/usr/bin/env bash
echo "246 Ensure actions as another user are always logged"

# Define arquivos a verificar (só se existirem)
files_to_check=()
[[ -f /etc/audit/audit.rules ]] && files_to_check+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && files_to_check+=("/etc/audit/rules.d/"*.rules)

# Expressão awk para validar as regras
awk_expr='/^ *-a *always,exit/ &&/ -F *arch=b(32|64)/ &&(/ -F *auid!=unset/||/ -F *auid!=-1/||/ -F *auid!=4294967295/) &&(/ -C *euid!=uid/||/ -C *uid!=euid/) &&/ -S *execve/ &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)'

# Verifica regras persistentes
persist_ok=false
if [[ ${#files_to_check[@]} -gt 0 ]]; then
    if awk "$awk_expr" "${files_to_check[@]}" 2>/dev/null | grep -q .; then
        persist_ok=true
    fi
fi

# Verifica regras carregadas no momento
active_ok=false
if auditctl -l 2>/dev/null | awk "$awk_expr" | grep -q .; then
    active_ok=true
fi

# Avaliação final
if $persist_ok && $active_ok; then
echo "✅ [APROVADO]: Regras de auditoria para ações como outro usuário estão corretamente configuradas (persistentes e ativas)"
elif ! $persist_ok && $active_ok; then
echo "⚠️ PARCIAL: Regras estão ativas, mas não persistentes (podem se perder após reboot)"
elif $persist_ok && ! $active_ok; then
echo "⚠️ PARCIAL: Regras estão configuradas, mas não estão ativas (recarregue com augenrules ou reinicie auditd)"
else
echo "⚠️[REPROVADO]: Regras de auditoria para ações como outro usuário NÃO encontradas"
fi