#!/usr/bin/env bash
echo "259 Ensure successful and unsuccessful attempts to use the chcon command are collected"

# Verificar se já existem regras de auditoria para o comando chcon
EXISTING_RULES=$(auditctl -l 2>/dev/null | \
  grep -E "\-a\s+always,exit" | \
  grep -E "\-F\s+perm=x" | \
  grep -E "\-F\s+auid>=1000" | \
  grep -E "\-F\s+path=/usr/bin/chcon" | \
  grep -E "key=\S+|\-k\s+\S+")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras de auditoria para chcon já existem. Nenhuma alteração necessária."
  exit 0
fi

# Se as regras não existirem, cria o arquivo de regras
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
if [[ -n "$UID_MIN" ]]; then
  cat <<EOF > /etc/audit/rules.d/50-perm_chng.rules
-a always,exit -F path=/usr/bin/chcon -F perm=x -F auid>=${UID_MIN} -F auid!=unset -k perm_chng
EOF

  echo "✅ Regras salvas em /etc/audit/rules.d/50-perm_chng.rules"

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