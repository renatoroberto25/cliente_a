#!/usr/bin/env bash
set -u
echo "[242] Garantir que os eventos que modificam SELinux (MAC) sejam coletados"

RULE_FILE="/etc/audit/rules.d/242-selinux.rules"
BACKUP="${RULE_FILE}.$(date +%F_%H%M%S).bak"

RULES='
-w /etc/selinux/ -p wa -k MAC-policy
'

if ! auditctl -l | grep -q "MAC-policy"; then
    [ -f "$RULE_FILE" ] && cp "$RULE_FILE" "$BACKUP"
    echo "$RULES" > "$RULE_FILE"
    augenrules --load
    echo "✅ Regras aplicadas"
else
    echo "✅ Já configurado"
fi