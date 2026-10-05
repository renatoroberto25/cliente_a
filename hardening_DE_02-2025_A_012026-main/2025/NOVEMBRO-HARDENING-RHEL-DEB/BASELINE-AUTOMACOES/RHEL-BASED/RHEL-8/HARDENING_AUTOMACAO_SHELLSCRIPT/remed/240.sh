#!/usr/bin/env bash
echo "[240] Garantir que os eventos de login e logout sejam coletados"

RULE_FILE="/etc/audit/rules.d/50-login.rules"

cat <<EOF > "$RULE_FILE"
# Regras adicionadas pela remediação 240 (HITSS Benchmark)
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock -p wa -k logins
EOF

augenrules --load && echo "✅ Regras aplicadas"
auditctl -s | grep -q "enabled.*2" && echo "⚠️ Reboot necessário"