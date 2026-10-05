#!/usr/bin/env bash
echo "251 Ensure unsuccessful file access attempts are collected"

RULE_FILE="/etc/audit/rules.d/50-access.rules"
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

if [[ -z "$UID_MIN" ]]; then
  echo "❌ ERRO: UID_MIN não encontrado em /etc/login.defs"
  exit 1
fi

echo "UID_MIN identificado como $UID_MIN"

# Verifica se as regras já existem
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "creat|open|openat|truncate|ftruncate.*exit=-EACCES|exit=-EPERM.*auid>=$UID_MIN")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras de auditoria já existem para tentativas de acesso a arquivos. Nenhuma alteração necessária."
  exit 0
fi

echo "Escrevendo regras em $RULE_FILE..."

cat <<EOF > "$RULE_FILE"
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>=$UID_MIN -F auid!=unset -k access
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM  -F auid>=$UID_MIN -F auid!=unset -k access
-a always,exit -F arch=b32 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>=$UID_MIN -F auid!=unset -k access
-a always,exit -F arch=b32 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM  -F auid>=$UID_MIN -F auid!=unset -k access
EOF

echo "✅ Regras gravadas com sucesso."

# Carrega as regras
echo "Aplicando regras com augenrules..."
if augenrules --load; then
  echo "✅ Regras carregadas com sucesso."
else
  echo "❌ Erro ao carregar regras com augenrules."
fi

# Verifica se é necessário reiniciar
if auditctl -s | grep -q "enabled.*2"; then
  echo "⚠️ AVISO: Reboot necessário para ativar as regras (modo 2 detectado)."
else
  echo "✅ Regras ativadas sem necessidade de reboot."
fi