#!/usr/bin/env bash
echo "[176] Remediação - Habilitar UsePAM no sshd"

SSHD_FILE="/etc/ssh/sshd_config"
BACKUP="$SSHD_FILE.bak_$(date +%Y%m%d_%H%M%S)"

[ -f "$SSHD_FILE" ] && cp "$SSHD_FILE" "$BACKUP" && echo "❗ Backup criado em $BACKUP"

# Garante que UsePAM esteja definido antes de qualquer Include
if grep -qE '^\s*UsePAM\s+' "$SSHD_FILE"; then
  sed -i 's/^\s*UsePAM\s\+.*/UsePAM yes/' "$SSHD_FILE"
else
  sed -i '/^#\?Include/i UsePAM yes' "$SSHD_FILE"
fi

# Testa e recarrega sshd
echo -e "\nValidando configuração do SSH..."
if sshd -t 2>/dev/null; then
  echo "✅ Configuração válida"
  systemctl reload sshd && echo "✅ sshd recarregado com sucesso"
else
  echo "⚠️ Erro na configuração do SSH. Verifique $SSHD_FILE ou o backup em $BACKUP"
  exit 1
fi