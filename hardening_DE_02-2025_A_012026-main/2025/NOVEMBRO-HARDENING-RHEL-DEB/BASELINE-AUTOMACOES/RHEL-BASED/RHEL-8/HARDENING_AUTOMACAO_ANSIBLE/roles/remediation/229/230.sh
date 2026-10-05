#!/usr/bin/env bash
echo "[230] Garantir que ações como outro usuário sejam sempre registradas"

RULE_FILE="/etc/audit/rules.d/50-scope.rules"
BACKUP="/etc/audit/rules.d/50-scope.rules.bak_$(date +%F_%T)"

# Regras exigidas
REQUIRED_RULES=(
"-w /etc/sudoers -p wa -k scope"
"-w /etc/sudoers.d -p wa -k scope"
)

# Backup se o arquivo já existir
if [[ -f "$RULE_FILE" ]]; then
    cp "$RULE_FILE" "$BACKUP"
    echo "Backup criado em $BACKUP"
fi

CHANGED=0
for RULE in "${REQUIRED_RULES[@]}"; do
    if ! grep -qF -- "$RULE" "$RULE_FILE" 2>/dev/null; then
        echo "$RULE" >> "$RULE_FILE"
        CHANGED=1
    fi
done

if [[ $CHANGED -eq 1 ]]; then
    echo "⚠️ Regras adicionadas em $RULE_FILE"
    augenrules --load
    if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
        echo "⚠️ Reboot required to fully load rules"
    fi
    echo "✅ Regra aplicada."
else
    echo "✅ Regras já configuradas. Nenhuma alteração necessária."
fi