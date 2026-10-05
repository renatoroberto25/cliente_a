#!/usr/bin/env bash
echo "[58 - 60] Remover informações sensíveis dos arquivos de banner"

regex="(\\\v|\\\r|\\\m|\\\s|\b$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '\"')\b)"
BANNER="Atenção: uso autorizado apenas para fins corporativos. Todas as atividades podem ser monitoradas."

for arquivo in /etc/motd /etc/issue /etc/issue.net; do
  if [ -f "$arquivo" ]; then
    if grep -Psiq -- "$regex" "$arquivo"; then
      echo "⚠️ Corrigindo $arquivo (removendo conteúdo sensível)"
      cp -p "$arquivo" "$arquivo.bak_$(date +%F_%H-%M-%S)"
      echo "$BANNER" > "$arquivo"
    else
      echo "✅ $arquivo já está em conformidade"
    fi
  else
    echo "ℹ️ $arquivo não existe. Criando com conteúdo padrão."
    echo "$BANNER" > "$arquivo"
  fi
done