#!/usr/bin/env bash
echo "255 Ensure session initiation information is collected"

# Verificar se já existem regras de auditoria para arquivos de sessão
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "utmp|wtmp|btmp.*p\s*wa.*key=session")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras de auditoria para informações de sessão já existem. Nenhuma alteração necessária."
  exit 0
fi

# Caso as regras não existam, cria o arquivo de regras
cat << EOF > /etc/audit/rules.d/50-session.rules
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session
EOF

echo "✅ Regras salvas em /etc/audit/rules.d/50-session.rules"

# Carregar as regras
augenrules --load
echo "Regras carregadas com sucesso"

# Verificar se o audit está habilitado e se um reboot é necessário
auditctl -s | grep -q "enabled 2" && echo "⚠️ Reboot necessário para aplicar as regras" || echo "✅ Regras aplicadas em tempo de execução"