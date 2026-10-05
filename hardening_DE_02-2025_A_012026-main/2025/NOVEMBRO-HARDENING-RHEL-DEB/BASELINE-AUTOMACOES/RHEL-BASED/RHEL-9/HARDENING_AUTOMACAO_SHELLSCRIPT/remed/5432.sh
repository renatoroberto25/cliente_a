#!/usr/bin/env bash

echo "[212] Garantir timeout padrão do shell (TMOUT=900, exportado e readonly)"

TMOUT_FILE="/etc/profile.d/50-tmout.sh"
BACKUP="${TMOUT_FILE}.bak.$(date +%Y%m%d%H%M%S)"

# Faz backup se existir
if [ -f "$TMOUT_FILE" ]; then
  cp -p "$TMOUT_FILE" "$BACKUP" && echo "🗂️ Backup criado: $BACKUP"
fi

# Garante que as três linhas existam corretamente
{
  echo "# Configurado por script Hitss 212"
  echo "TMOUT=900"
  echo "readonly TMOUT"
  echo "export TMOUT"
} > "$TMOUT_FILE"

chmod 644 "$TMOUT_FILE" && echo "✅ TMOUT configurado corretamente em $TMOUT_FILE"

exit 0