#!/usr/bin/env bash
echo "249 Ensure events that modify the system's network environment are collected"

RULE_FILE="/etc/audit/rules.d/50-system_locale.rules"

# Regras esperadas conforme o Hitss Benchmark
EXPECTED_RULES=$(cat << 'EOF'
# Regras adicionadas por remediação da 249 (Hitss Benchmark)
-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/hostname -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale
-w /etc/sysconfig/network-scripts/ -p wa -k system-locale
-w /etc/NetworkManager -p wa -k system-locale
EOF
)

# Verifica se as regras já existem
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "system-locale")

if [[ -n "$EXISTING_RULES" ]]; then
    echo "✅ Regras para eventos que modificam o ambiente de rede do sistema já estão coletadas. Nenhuma alteração necessária."
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