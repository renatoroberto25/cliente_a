#!/usr/bin/env bash
echo "[254] Ensure successful file system mounts are collected"

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

if [[ -z "$UID_MIN" ]]; then
  echo "❌ ERRO: UID_MIN não encontrado em /etc/login.defs"
  exit 1
fi

RULES_FILE="/etc/audit/rules.d/50-mounts.rules"

# Garante que o diretório exista
mkdir -p /etc/audit/rules.d

# Verifica se já existe regra no disco
if grep -q "mount" "$RULES_FILE" 2>/dev/null; then
  echo "✅ Regras já existem em $RULES_FILE. Nenhuma alteração necessária."
else
  cat <<EOF > "$RULES_FILE"
-a always,exit -F arch=b32 -S mount -F auid>=$UID_MIN -F auid!=-1 -k mounts
-a always,exit -F arch=b64 -S mount -F auid>=$UID_MIN -F auid!=-1 -k mounts
EOF
  echo "✅ Regras salvas em $RULES_FILE"
fi

# Recarrega as regras
if command -v augenrules &>/dev/null; then
  augenrules --load && echo "🔄 Regras recarregadas com augenrules"
elif systemctl is-active --quiet auditd; then
  systemctl reload auditd && echo "🔄 Auditd recarregado"
fi

# Verifica runtime
if auditctl -l 2>/dev/null | grep -q "mount"; then
  echo "✅ Regras aplicadas em tempo de execução"
else
  echo "⚠️ Reboot ou reload do auditd pode ser necessário"
fi