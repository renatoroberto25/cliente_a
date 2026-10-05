#!/usr/bin/env bash
echo "248 Ensure events that modify date and time information are collected"

RULE_FILE="/etc/audit/rules.d/50-time-change.rules"

# Regras esperadas conforme Hitss Benchmark
EXPECTED_RULES=$(cat << 'EOF'
# Regras adicionadas por remediação da 248 (Hitss Benchmark)
-a always,exit -F arch=b64 -S adjtimex,settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex,settimeofday -k time-change
-a always,exit -F arch=b64 -S clock_settime -F a0=0x0 -k time-change
-a always,exit -F arch=b32 -S clock_settime -F a0=0x0 -k time-change
-w /etc/localtime -p wa -k time-change
EOF
)

# Verifica se as regras já existem
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "time-change")

if [[ -n "$EXISTING_RULES" ]]; then
    echo "✅ Regras para eventos que modificam informações de data e hora já estão coletadas. Nenhuma alteração necessária."
    exit 0
fi

# Aplica as regras no arquivo
echo "$EXPECTED_RULES" > "$RULE_FILE"
echo "✅ Regras gravadas em $RULE_FILE"

# Recarrega com augenrules
echo "🔄 Recarregando regras com augenrules..."
if augenrules --load; then
    echo "✅ Regras carregadas com sucesso."
else
    echo "❌ Erro ao carregar regras com augenrules."
fi

# Verifica se o auditd está em modo immutable
if auditctl -s | grep -q '^enabled[^0-9]*2'; then
    echo "⚠️ Reboot necessário: auditd está em modo immutable (enabled 2)"
else
    echo "✅ Regras aplicadas e carregadas com sucesso"
fi