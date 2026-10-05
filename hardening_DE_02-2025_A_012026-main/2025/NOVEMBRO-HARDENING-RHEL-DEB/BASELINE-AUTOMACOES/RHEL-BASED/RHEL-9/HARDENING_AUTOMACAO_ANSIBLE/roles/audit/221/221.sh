#!/usr/bin/env bash

# Lista de pacotes para verificar
pacotes=(
  ftp
  openldap-clients
  ypbind
  telnet
  tftp
)

# Função para verificar se um pacote está instalado
verificar_pacote() {
  local pacote="$1"

  # Verifica se o pacote está instalado, usando 'rpm' ou 'dnf' (dependendo da disponibilidade)
  if command -v rpm &>/dev/null; then
    if rpm -q "$pacote" &>/dev/null; then
echo "⚠️[REPROVADO]: Pacote $pacote está instalado. Por favor, remova-o."
    else
echo "✅ [APROVADO]: Pacote $pacote não está instalado."
    fi
  elif command -v dnf &>/dev/null; then
    if dnf list installed "$pacote" &>/dev/null; then
echo "⚠️[REPROVADO]: Pacote $pacote está instalado. Por favor, remova-o."
    else
echo "✅ [APROVADO]: Pacote $pacote não está instalado."
    fi
  else
echo "⚠️ ERRO: Nenhum gerenciador de pacotes encontrado (rpm ou dnf)."
  fi
}

# Verificar cada pacote na lista
for pacote in "${pacotes[@]}"; do
  verificar_pacote "$pacote"
done
