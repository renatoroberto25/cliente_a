#!/usr/bin/env bash
echo "[236] Garantir que os eventos que modificam as informações de usuários/grupos sejam coletados"

RULE_FILE="/etc/audit/rules.d/50-identity.rules"

cat <<EOF > "$RULE_FILE"
# Regras adicionadas pela remediação 236 (HITSS Benchmark)
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
-w /etc/nsswitch.conf -p wa -k identity
-w /etc/pam.conf -p wa -k identity
-w /etc/pam.d -p wa -k identity
EOF

augenrules --load && echo "✅ Regras aplicadas"
auditctl -s | grep -q "enabled.*2" && echo "⚠️ Reboot necessário"