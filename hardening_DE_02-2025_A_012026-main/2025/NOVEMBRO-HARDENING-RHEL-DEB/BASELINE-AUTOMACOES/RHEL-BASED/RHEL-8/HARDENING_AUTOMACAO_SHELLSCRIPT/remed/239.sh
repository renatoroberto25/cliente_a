#!/usr/bin/env bash
echo "[239] Garantir que as informações de início de sessão sejam coletadas"

RULE_FILE="/etc/audit/rules.d/50-session.rules"

cat <<EOF > "$RULE_FILE"
# Regras adicionadas pela remediação 239 (HITSS Benchmark)
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session
EOF

augenrules --load && echo "✅ Regras aplicadas"
auditctl -s | grep -q "enabled.*2" && echo "⚠️ Reboot necessário"