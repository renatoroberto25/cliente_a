#!/usr/bin/env bash
echo "258 Ensure events that modify the system's Mandatory Access Controls are collected"

# Verificar se já existem regras de auditoria para MAC
EXISTING_RULES=$(auditctl -l 2>/dev/null | \
  grep -E "\-w\s+/etc/selinux" | \
  grep -E "\-p\s+wa" | \
  grep -E "key=\S+|\-k\s+\S+")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras de auditoria para MAC já existem. Nenhuma alteração necessária."
  exit 0
fi

# Caso as regras não existam, cria o arquivo de regras
cat <<EOF > /etc/audit/rules.d/50-MAC-policy.rules
-w /etc/selinux -p wa -k MAC-policy
-w /usr/share/selinux -p wa -k MAC-policy
EOF

echo "✅ Regras salvas em /etc/audit/rules.d/50-MAC-policy.rules"

# Carregar as regras
augenrules --load && echo "Regras carregadas com sucesso"

# Verificar se o audit está habilitado e se um reboot é necessário
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
  echo "⚠️ Reboot necessário para aplicar as regras completamente"
else
  echo "✅ Regras aplicadas em tempo de execução"
fi