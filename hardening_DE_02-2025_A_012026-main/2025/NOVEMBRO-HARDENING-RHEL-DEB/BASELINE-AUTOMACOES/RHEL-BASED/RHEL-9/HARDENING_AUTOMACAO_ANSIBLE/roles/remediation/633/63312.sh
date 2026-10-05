#!/usr/bin/env bash
echo "256 Ensure login and logout events are collected"

# Verificar se já existem regras de auditoria para login/logout
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "lastlog|faillock.*p\s*wa.*key=logins")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras de auditoria para login/logout já existem. Nenhuma alteração necessária."
  exit 0
fi

# Caso as regras não existam, cria o arquivo de regras
cat << EOF > /etc/audit/rules.d/50-login.rules
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock -p wa -k logins
EOF

echo "✅ Regras salvas em /etc/audit/rules.d/50-login.rules"

# Carregar as regras
augenrules --load
echo "Regras carregadas com sucesso"

# Verificar se o audit está habilitado e se um reboot é necessário
auditctl -s | grep -q "enabled 2" && echo "⚠️ Reboot necessário para aplicar as regras" || echo "✅ Regras aplicadas em tempo de execução"