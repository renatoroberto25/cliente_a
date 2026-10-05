#!/usr/bin/env bash
echo "254 Ensure successful file system mounts are collected"

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

if [[ -z "$UID_MIN" ]]; then
  echo "❌ ERRO: UID_MIN não encontrado em /etc/login.defs"
  exit 1
fi

# Verificar se já existem regras de auditoria de montagens
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "mount.*auid>=$UID_MIN.*auid!=unset.*key=mounts")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras de auditoria para montagens já existem. Nenhuma alteração necessária."
  exit 0
fi

# Caso as regras não existam, cria o arquivo de regras
cat <<EOF > /etc/audit/rules.d/50-mounts.rules
-a always,exit -F arch=b32 -S mount -F auid>=$UID_MIN -F auid!=unset -k mounts
-a always,exit -F arch=b64 -S mount -F auid>=$UID_MIN -F auid!=unset -k mounts
EOF

echo "✅ Regras salvas em /etc/audit/rules.d/50-mounts.rules"

# Carregar as regras
augenrules --load && echo "🔄 Regras carregadas com sucesso"

# Verificar se o audit está habilitado e se um reboot é necessário
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
  echo "⚠️ Reboot necessário para aplicar as regras completamente"
else
  echo "✅ Regras aplicadas em tempo de execução"
fi