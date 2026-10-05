#!/usr/bin/env bash
echo "246 Ensure actions as another user are always logged remediation"

RULE_FILE="/etc/audit/rules.d/50-user_emulation.rules"

# Verifica se a regra já existe
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "euid!=uid.*execve")

if [[ -n "$EXISTING_RULES" ]]; then
    echo "✅ A regra de emulação de usuário já está configurada. Nenhuma alteração necessária."
    exit 0
fi

# Escreve as regras necessárias com comentário de remediação
cat <<EOF > "$RULE_FILE"
# Regras adicionadas por remediação da 246 (HITSS Benchmark)
-a always,exit -F arch=b64 -C euid!=uid -F auid!=unset -S execve -k user_emulation
-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k user_emulation
EOF

echo "✅ Regras gravadas em $RULE_FILE:"
cat "$RULE_FILE"

# Recarrega as regras de auditoria
echo "Recarregando regras com augenrules..."
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