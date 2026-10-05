#!/usr/bin/env bash
echo "257 Ensure file deletion events by users are collected"

# Obtém o UID mínimo a partir do /etc/login.defs
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

if [[ -z "$UID_MIN" ]]; then
  echo "❌ ERRO: UID_MIN não encontrado em /etc/login.defs"
  exit 1
fi

# Verifica se já existem regras de auditoria para exclusão de arquivos
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "unlink|unlinkat|rename|renameat.*auid>=$UID_MIN.*auid!=unset.*key=delete")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras de auditoria para exclusão de arquivos já existem. Nenhuma alteração necessária."
  exit 0
fi

# Caso as regras não existam, cria o arquivo de regras
cat <<EOF > /etc/audit/rules.d/50-delete.rules
-a always,exit -F arch=b32 -S unlink,unlinkat,rename,renameat -F auid>=$UID_MIN -F auid!=unset -k delete
-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=$UID_MIN -F auid!=unset -k delete
EOF

echo "✅ Regras salvas em /etc/audit/rules.d/50-delete.rules"

# Carregar as regras
augenrules --load && echo "Regras carregadas com sucesso"

# Verificar se o audit está habilitado e se um reboot é necessário
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
  echo "⚠️ Reboot necessário para aplicar as regras completamente"
else
  echo "✅ Regras aplicadas em tempo de execução"
fi