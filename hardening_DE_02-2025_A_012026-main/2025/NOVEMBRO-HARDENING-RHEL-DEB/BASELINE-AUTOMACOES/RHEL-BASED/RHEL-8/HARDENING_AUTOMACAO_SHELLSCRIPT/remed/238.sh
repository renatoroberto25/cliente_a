#!/usr/bin/env bash
set -u
echo "[238] Garantir que as montagens bem-sucedidas do sistema de arquivos sejam coletadas"

RULE_FILE="/etc/audit/rules.d/238-mounts.rules"
BACKUP="${RULE_FILE}.$(date +%F_%H%M%S).bak"

RULES='
-a always,exit -F arch=b64 -S mount -k mounts
-a always,exit -F arch=b32 -S mount -k mounts
'

if ! auditctl -l | grep -q "mounts"; then
    [ -f "$RULE_FILE" ] && cp "$RULE_FILE" "$BACKUP"
    echo "$RULES" > "$RULE_FILE"
    augenrules --load
    echo "✅ Regras aplicadas"
else
    echo "✅ Já configurado"
fi