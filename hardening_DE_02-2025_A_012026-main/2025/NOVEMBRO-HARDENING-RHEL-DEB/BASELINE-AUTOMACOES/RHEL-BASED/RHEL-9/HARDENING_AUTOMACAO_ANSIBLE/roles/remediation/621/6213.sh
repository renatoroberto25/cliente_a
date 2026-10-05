#!/usr/bin/env bash

echo "[219] Configurar rotação do journald"

CONFIG_DIR="/etc/systemd/journald.conf.d"
CONFIG_FILE="$CONFIG_DIR/hardening-journal.conf"
BACKUP_FILE="${CONFIG_FILE}.bak.$(date +%Y%m%d%H%M%S)"

# Cabeçalho padrão
HEADER="[Journal]"

# Parâmetros obrigatórios conforme baseline
PARAMS=(
  "SystemMaxUse=1G"
  "SystemKeepFree=500M"
  "RuntimeMaxUse=200M"
  "RuntimeKeepFree=50M"
  "MaxFileSec=1month"
)

mkdir -p "$CONFIG_DIR"

# Faz backup se o arquivo já existir
if [ -f "$CONFIG_FILE" ]; then
  cp -p "$CONFIG_FILE" "$BACKUP_FILE" && echo "🗂️ Backup criado: $BACKUP_FILE"
fi

# Cria arquivo novo se não existir
if [ ! -f "$CONFIG_FILE" ]; then
  echo "$HEADER" > "$CONFIG_FILE"
fi

# Garante cabeçalho
if ! grep -q "^\[Journal\]" "$CONFIG_FILE"; then
  sed -i '1i [Journal]' "$CONFIG_FILE"
fi

# Adiciona parâmetros ausentes
for param in "${PARAMS[@]}"; do
  chave="${param%%=*}"
  if ! grep -Eiq "^\s*${chave}\s*=" "$CONFIG_FILE"; then
    echo "$param" >> "$CONFIG_FILE"
    echo "✔ Parâmetro adicionado: $param"
  fi
done

# Reinicia journald
echo "Reiniciando systemd-journald..."
if systemctl restart systemd-journald.service; then
  echo "✅ systemd-journald reiniciado com sucesso"
else
  echo "⚠️ Falha ao reiniciar systemd-journald"
fi

exit 0