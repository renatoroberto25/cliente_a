#!/usr/bin/env bash

echo "270 Ensure audit configuration files mode is configured"

# Encontra arquivos de configuração do audit com permissões incorretas
arquivos_config_incorretos=$(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) ! -perm 600)

if [ -n "$arquivos_config_incorretos" ]; then
  echo "⚠️ Os seguintes arquivos de configuração do audit possuem permissões incorretas:"
  echo "$arquivos_config_incorretos"
  echo "Corrigindo permissões para 600 (rw-------)..."
  find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) -exec chmod 600 {} +
  echo "✅ Permissões corrigidas."
else
  echo "[✅ SUCESSO]: - Todos os arquivos de configuração do audit possuem permissões adequadas (600)."
fi