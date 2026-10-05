#!/bin/bash

# Lista de pacotes para verificar
pacotes=(
  ftp
  openldap-clients
  ypbind
  telnet
  tftp
)

# Função para verificar e desinstalar pacotes
desinstala_pacote() {
  local pacote="$1"

  # Verifica se o pacote está instalado antes de tentar remover
  if dnf list installed "$pacote" &> /dev/null; then
    echo "🔹 Removendo $pacote..."
    if dnf remove -y "$pacote" &> /dev/null; then
      echo "✅ Pacote $pacote foi desinstalado com sucesso."
    else
      echo "❌ Falha ao remover $pacote."
    fi
  else
    echo "⚠️ Pacote $pacote não está instalado, nada a fazer."
  fi
}

# Verificar e remover cada pacote da lista
for pacote in "${pacotes[@]}"; do
  desinstala_pacote "$pacote"
done

echo "🎯 ** CONCLUÍDO **"
