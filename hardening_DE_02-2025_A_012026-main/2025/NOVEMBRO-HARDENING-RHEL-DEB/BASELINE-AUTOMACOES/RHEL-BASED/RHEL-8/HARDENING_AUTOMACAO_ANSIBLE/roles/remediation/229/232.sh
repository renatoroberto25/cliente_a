#!/usr/bin/env bash
echo "[232] Garantir que os eventos que modificam as informações de data e hora sejam coletados"

RULE_FILE="/etc/audit/rules.d/50-time-change.rules"

EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -q "time-change" && echo ok)

if [[ "$EXISTING_RULES" == "ok" ]]; then
    echo "✅ Já configurado."
    exit 0
fi

cat <<EOF > "$RULE_FILE"
# Regras adicionadas pela remediação 232 (HITSS Benchmark)
-a always,exit -F arch=b64 -S adjtimex,settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex,settimeofday -k time-change
-a always,exit -F arch=b64 -S clock_settime -F a0=0x0 -k time-change
-a always,exit -F arch=b32 -S clock_settime -F a0=0x0 -k time-change
-w /etc/localtime -p wa -k time-change
EOF

augenrules --load && echo "✅ Regras aplicadas"
auditctl -s | grep -q "enabled.*2" && echo "⚠️ Reboot necessário"