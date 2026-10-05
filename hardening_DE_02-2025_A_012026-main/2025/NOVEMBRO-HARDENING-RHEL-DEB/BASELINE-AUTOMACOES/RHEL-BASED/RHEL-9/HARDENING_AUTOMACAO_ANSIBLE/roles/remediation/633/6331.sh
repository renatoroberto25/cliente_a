#!/usr/bin/env bash
echo "245 Ensure changes to system administration scope (sudoers) is collected remediation"

RULE_FILE="/etc/audit/rules.d/50-scope.rules"

# Verifica se a regra já existe
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "/etc/sudoers|/etc/sudoers.d")

if [[ -n "$EXISTING_RULES" ]]; then
    echo "✅ As regras para mudanças no sudoers já estão configuradas. Nenhuma alteração necessária."
    exit 0
fi

# Escreve as regras necessárias com comentário de remediação
cat <<EOF > "$RULE_FILE"
# Regras adicionadas por remediação da 245 (HITSS Benchmark)
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d -p wa -k scope
EOF

echo "✅ Regras gravadas em $RULE_FILE:"
cat "$RULE_FILE"

# Recarrega as regras de auditoria
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