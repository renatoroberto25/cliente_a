#!/usr/bin/env bash
echo "247 Ensure events that modify the sudo log file are collected"

# Obtém o caminho do arquivo de log do sudo, se configurado
SUDO_LOG_FILE=$(grep -r logfile /etc/sudoers* 2>/dev/null | sed -e 's/.*logfile=//;s/,? .*//' -e 's/"//g')

if [[ -z "$SUDO_LOG_FILE" ]]; then
echo "⚠️[REPROVADO]: Caminho do log do sudo não encontrado nos arquivos sudoers. Verifique a diretiva 'Defaults logfile='"
    exit 0
fi

echo "Caminho do log do sudo encontrado: $SUDO_LOG_FILE"

# Verifica se há regras de auditoria no disco
files_to_check=()
[[ -f /etc/audit/audit.rules ]] && files_to_check+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && files_to_check+=("/etc/audit/rules.d/"*.rules)

DISK_RESULT=$(awk "/^ *-w/ && /${SUDO_LOG_FILE//\//\\/}/ && / +-p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)" "${files_to_check[@]}" 2>/dev/null)

if [[ -n "$DISK_RESULT" ]]; then
echo "✅ [APROVADO]: Regra de auditoria encontrada no disco para o log do sudo:"
echo "$DISK_RESULT"
else
echo "⚠️[REPROVADO]: Nenhuma regra de auditoria encontrada no disco para $SUDO_LOG_FILE"
    exit 0
fi

# Verifica se há regras carregadas em tempo de execução
LOADED_RESULT=$(auditctl -l 2>/dev/null | awk "/^ *-w/ && /${SUDO_LOG_FILE//\//\\/}/ && / +-p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)")

if [[ -n "$LOADED_RESULT" ]]; then
echo "✅ [APROVADO]: Regra de auditoria carregada encontrada para o log do sudo:"
echo "$LOADED_RESULT"
else
echo "⚠️[REPROVADO]: Nenhuma regra de auditoria carregada para $SUDO_LOG_FILE"
    exit 0
fi