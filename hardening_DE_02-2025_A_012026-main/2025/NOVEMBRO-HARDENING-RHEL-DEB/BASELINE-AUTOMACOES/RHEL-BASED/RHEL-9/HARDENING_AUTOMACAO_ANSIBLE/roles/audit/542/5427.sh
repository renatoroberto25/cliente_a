#!/usr/bin/env bash

echo -e "\n[209] Verificar se contas de sistema possuem shell válido"
echo "--- Iniciando análise das contas de serviço ---"

l_valid_shells=$(awk '!/nologin|false/ {print $0}' /etc/shells | paste -sd '|')
uid_min=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
[ -z "$uid_min" ] && uid_min=1000

resultado=$(awk -v pat="^(${l_valid_shells})$" -v uid_min="$uid_min" -F: '
  ($1 !~ /^(root|halt|sync|shutdown|nfsnobody)$/ && ($3 < uid_min || $3 == 65534) && $NF ~ pat) {
    print "⚠️[REPROVADO]: Conta \"" $1 "\" possui shell válido: " $NF
  }
' /etc/passwd)

if [[ -z "$resultado" ]]; then
  echo "✅ [APROVADO]: Nenhuma conta de sistema com shell válido encontrada"
else
  echo "$resultado"
fi

exit 0