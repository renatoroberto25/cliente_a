#!/usr/bin/env bash
echo "[229] Garantir que as alterações no escopo de administração do sistema (sudoers) sejam coletadas"

RULE_FILE="/etc/audit/rules.d/50-scope.rules"

EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "/etc/sudoers|/etc/sudoers.d")

if [[ -n "$EXISTING_RULES" ]]; then
    echo "✅ Regras já configuradas. Nenhuma alteração necessária."
    exit 0
fi

cat <<EOF > "$RULE_FILE"
# Regras adicionadas pela remediação 229 (HITSS Benchmark)
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d -p wa -k scope
EOF

augenrules --load && echo "✅ Regras aplicadas" || echo "❌ Erro ao carregar"
auditctl -s | grep -q "enabled.*2" && echo "⚠️ Reboot necessário (modo immutable)"