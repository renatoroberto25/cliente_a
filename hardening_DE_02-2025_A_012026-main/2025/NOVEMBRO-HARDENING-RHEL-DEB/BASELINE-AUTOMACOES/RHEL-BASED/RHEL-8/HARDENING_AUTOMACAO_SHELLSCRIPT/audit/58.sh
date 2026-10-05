#!/usr/bin/env bash
echo "[58 - 60] Verificar se os banners do sistema expõem informações sensíveis"

# Expressões de sistema a serem evitadas
regex="(\\\v|\\\r|\\\m|\\\s|\b$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '\"')\b)"

for arquivo in /etc/motd /etc/issue /etc/issue.net; do
  echo "Verificando: $arquivo"
  if [ -f "$arquivo" ]; then
    if grep -Psiq -- "$regex" "$arquivo"; then
      echo "⚠️ REPROVADO - $arquivo contém informações do sistema."
    else
      echo "✅ APROVADO - $arquivo não contém informações sensíveis."
    fi
  else
    echo "⚠️ REPROVADO - $arquivo não existe."
  fi
done