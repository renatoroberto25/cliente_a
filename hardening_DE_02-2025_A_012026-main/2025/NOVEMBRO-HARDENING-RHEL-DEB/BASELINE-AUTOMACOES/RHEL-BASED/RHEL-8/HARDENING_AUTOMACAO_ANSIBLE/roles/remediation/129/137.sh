#!/usr/bin/env bash
echo "[137] - Restringir uso do 'at' a usuários autorizados"

# Verifica se o at está instalado
if ! rpm -q at &>/dev/null; then
  echo "✅ at não instalado — nenhuma ação necessária"
  exit 0
fi

group="root"
getent group daemon &>/dev/null && group="daemon"

# Corrige at.allow
if [ ! -e /etc/at.allow ]; then
  touch /etc/at.allow
  echo "root" > /etc/at.allow
  echo "✅ /etc/at.allow criado"
fi
chown root:$group /etc/at.allow
chmod 640 /etc/at.allow
echo "✅ /etc/at.allow configurado"

# Corrige at.deny (se existir)
if [ -e /etc/at.deny ]; then
  chown root:$group /etc/at.deny
  chmod 640 /etc/at.deny
  echo "✅ /etc/at.deny configurado"
else
  echo "✅ /etc/at.deny ausente (OK)"
fi