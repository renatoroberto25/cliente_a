#!/usr/bin/env bash
echo "[235] Garantir que acessos negados a arquivos sejam coletados"

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
RULES=(
"-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EACCES -F auid>=$UID_MIN -F auid!=unset -k access"
"-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EPERM  -F auid>=$UID_MIN -F auid!=unset -k access"
)

FILE="/etc/audit/rules.d/hitss-235.rules"
mkdir -p /etc/audit/rules.d
cp "$FILE" "${FILE}.bak.$(date +%F_%T)" 2>/dev/null

ADDED=0
for RULE in "${RULES[@]}"; do
    if ! grep -RqF "$RULE" /etc/audit/rules.d/*.rules; then
        echo "$RULE" >> "$FILE"
        ADDED=1
    fi
done

if [[ $ADDED -eq 1 ]]; then
    augenrules --load
    echo "✅ Regras aplicadas."
else
    echo "✅ Regras já existentes."
fi