#!/usr/bin/env bash
echo "[233] Garantir que os eventos que modificam o ambiente de rede do sistema sejam coletados"

RULE_FILE="/etc/audit/rules.d/50-system-locale.rules"

EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -q "system-locale" && echo ok)

if [[ "$EXISTING_RULES" == "ok" ]]; then
    echo "✅ Já configurado."
    exit 0
fi

cat <<EOF > "$RULE_FILE"
# Regras adicionadas pela remediação 233 (HITSS Benchmark)
-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/hostname -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale
-w /etc/NetworkManager -p wa -k system-locale
EOF

augenrules --load && echo "✅ Regras aplicadas"
auditctl -s | grep -q "enabled.*2" && echo "⚠️ Reboot necessário"