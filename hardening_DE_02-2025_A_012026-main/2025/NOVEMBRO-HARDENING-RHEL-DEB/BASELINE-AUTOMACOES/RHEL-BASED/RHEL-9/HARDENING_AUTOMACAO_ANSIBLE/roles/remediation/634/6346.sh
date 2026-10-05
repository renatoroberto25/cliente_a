#!/usr/bin/env bash

echo "271 Ensure audit configuration files owner is configured"

# Encontra arquivos de configuração do audit que não pertencem ao usuário root
arquivos_dono_incorreto=$(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) ! -user root)

if [ -n "$arquivos_dono_incorreto" ]; then
  echo "⚠️ Os seguintes arquivos não pertencem ao usuário root:"
  echo "$arquivos_dono_incorreto"
  echo "Corrigindo o proprietário para root..."
  find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) -exec chown root {} +
  echo "✅ Proprietário corrigido para root."
else
  echo "[✅ SUCESSO]: - Todos os arquivos de configuração do audit pertencem ao usuário root."
fi