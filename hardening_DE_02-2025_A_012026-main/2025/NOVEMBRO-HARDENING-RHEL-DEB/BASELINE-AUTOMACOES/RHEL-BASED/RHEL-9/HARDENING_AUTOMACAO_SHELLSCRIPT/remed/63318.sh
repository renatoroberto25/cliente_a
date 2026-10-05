#!/usr/bin/env bash
echo "262 Ensure successful and unsuccessful attempts to use the usermod command are collected"

# Verificar se já existem regras de auditoria para o comando usermod
EXISTING_RULES=$(auditctl -l 2>/dev/null | \
  grep -E "\-a\s+always,exit" | \
  grep -E "\-F\s+perm=x" | \
  grep -E "\-F\s+auid>=1000" | \
  grep -E "\-F\s+path=/usr/sbin/usermod" | \
  grep -E "key=\S+|\-k\s+\S+")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras de auditoria para usermod já existem. Nenhuma alteração necessária."
  exit 0
fi

# Se as regras não existirem, cria o arquivo de regras
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
if [[ -n "$UID_MIN" ]]; then
  cat <<EOF > /etc/audit/rules.d/50-usermod.rules
-a always,exit -F path=/usr/sbin/usermod -F perm=x -F auid>=${UID_MIN} -F auid!=unset -k usermod
EOF

  echo "✅ Regras salvas em /etc/audit/rules.d/50-usermod.rules"

  # Carregar as regras
  augenrules --load && echo "Regras carregadas com sucesso"

  # Verificar se o audit está habilitado e se um reboot é necessário
  if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    echo "⚠️ Reboot necessário para aplicar as regras completamente"
  else
    echo "✅ Regras aplicadas em tempo de execução"
  fi
else
  echo "ERROR: Variável 'UID_MIN' não está definida."
fi