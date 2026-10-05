#!/usr/bin/env bash
echo "[241] Garantir que exclusão de arquivos seja coletada"

RULES=(
"-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=unset -k delete"
)

FILE="/etc/audit/rules.d/hitss-241.rules"
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