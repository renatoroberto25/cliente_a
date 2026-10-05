#!/usr/bin/env bash
echo "263 Ensure kernel module loading, unloading and modification is collected"

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

if [[ -z "$UID_MIN" ]]; then
  echo "ERROR: Variável 'UID_MIN' não está definida."
  exit 1
fi

# Verificar se já existem regras
EXISTING_RULES=$(auditctl -l 2>/dev/null | \
  grep -E "\-a\s+always,exit" | \
  grep -E "\-F\s+auid>=$UID_MIN" | \
  grep -E "\-F\s+auid!=(unset|-1|4294967295)" | \
  grep -E "\-S\s+(init_module|finit_module|delete_module|create_module|query_module)|\-F\s+path=/usr/bin/kmod" | \
  grep -E "key=\S+|\-k\s+\S+")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras já existem. Nenhuma alteração necessária."
  exit 0
fi

# Criar regras
cat <<EOF > /etc/audit/rules.d/50-kernel_modules.rules
-a always,exit -F arch=b64 -S init_module,finit_module,delete_module,create_module,query_module -F auid>=$UID_MIN -F auid!=unset -k kernel_modules
-a always,exit -F path=/usr/bin/kmod -F perm=x -F auid>=$UID_MIN -F auid!=unset -k kernel_modules
EOF

echo "✅ Regras criadas em /etc/audit/rules.d/50-kernel_modules.rules"

# Carregar as regras
augenrules --load && echo "Regras carregadas com sucesso"

# Verificar necessidade de reboot
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
  echo "⚠️ Reboot necessário para aplicar as regras completamente"
else
  echo "✅ Regras aplicadas em tempo de execução"
fi