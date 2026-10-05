#!/usr/bin/env bash
echo "247 Ensure events that modify the sudo log file are collected"

RULE_FILE="/etc/audit/rules.d/50-sudo_log.rules"

# Obtém o caminho do log do sudo
SUDO_LOG_FILE=$(grep -r logfile /etc/sudoers* 2>/dev/null | sed -e 's/.*logfile=//;s/,? .*//' -e 's/\"//g')

if [[ -z "$SUDO_LOG_FILE" ]]; then
    echo "❌ ERRO: Caminho do log do sudo não encontrado. Verifique a diretiva 'Defaults logfile=' no sudoers."
    exit 1
fi

echo "✅ Caminho do log do sudo identificado: $SUDO_LOG_FILE"

# Verifica se a regra já existe
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "$SUDO_LOG_FILE")

if [[ -n "$EXISTING_RULES" ]]; then
    echo "✅ Regra para o arquivo de log do sudo já está coletada. Nenhuma alteração necessária."
    exit 0
fi

# Escreve a regra no arquivo
echo "# Regra adicionada por remediação da 247 (HITSS Benchmark)" > "$RULE_FILE"
echo "-w $SUDO_LOG_FILE -p wa -k sudo_log_file" >> "$RULE_FILE"

echo "✅ Regra gravada em $RULE_FILE:"
cat "$RULE_FILE"

# Recarrega as regras com augenrules
echo "🔄 Recarregando regras com augenrules..."
if augenrules --load; then
    echo "✅ Regras carregadas com sucesso."
else
    echo "❌ Erro ao carregar regras com augenrules."
fi

# Verifica se auditd está em modo immutable
if auditctl -s | grep -q '^enabled[^0-9]*2'; then
    echo "⚠️ Reboot necessário para carregar as regras: auditd está em modo immutable (enabled 2)"
else
    echo "✅ Regras aplicadas e carregadas com sucesso"
fi