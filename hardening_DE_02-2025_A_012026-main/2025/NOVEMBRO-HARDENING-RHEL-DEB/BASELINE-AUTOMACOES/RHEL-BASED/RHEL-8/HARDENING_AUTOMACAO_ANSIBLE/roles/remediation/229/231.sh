#!/usr/bin/env bash
echo "[231] Garantir que eventos que modificam o log do sudo sejam coletados"

# Descobre logfile do sudo
SUDO_LOG_FILE=$(grep -E 'Defaults\s+logfile=' /etc/sudoers /etc/sudoers.d/* 2>/dev/null \
  | sed -E 's/.*logfile="?([^", ]+).*/\1/' | head -n1)

if [[ -z "$SUDO_LOG_FILE" ]]; then
    echo "⚠️ Nenhum logfile definido em sudoers. Avaliar habilitar: Defaults logfile=/var/log/sudo.log"
    exit 0
fi

RULE="-w $SUDO_LOG_FILE -p wa -k sudo_log_file"
FILE="/etc/audit/rules.d/hitss-231.rules"

# Backup
[[ -f "$FILE" ]] && cp "$FILE" "${FILE}.bak.$(date +%F_%T)"

if grep -RqF "$RULE" /etc/audit/rules.d/*.rules; then
    echo "✅ Regra já existente."
else
    echo "$RULE" >> "$FILE"
    augenrules --load
    echo "✅ Regra aplicada."
fi