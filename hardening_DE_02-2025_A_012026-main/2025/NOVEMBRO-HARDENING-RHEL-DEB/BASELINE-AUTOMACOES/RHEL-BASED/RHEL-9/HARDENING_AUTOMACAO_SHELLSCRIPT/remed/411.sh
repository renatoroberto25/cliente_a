#!/usr/bin/env bash
echo -e "\n[135] Remediação – Certifique-se de que o nftables esteja instalado"

# Verifica se o comando 'nft' está disponível
if ! command -v nft &>/dev/null; then
  echo "🔄 Instalando o pacote 'nftables'..."
  if command -v dnf &>/dev/null; then
    dnf -y install nftables
  elif command -v yum &>/dev/null; then
    yum -y install nftables
  else
    echo "[❌ FALHA] Nenhum gerenciador de pacotes compatível encontrado (dnf/yum)"
    exit 1
  fi

  # Verifica se a instalação foi bem-sucedida
  if command -v nft &>/dev/null; then
    echo "[✅ SUCESSO] Pacote 'nftables' instalado com sucesso"
  else
    echo "[❌ FALHA] Não foi possível instalar o 'nftables'"
    exit 1
  fi
else
  echo "[✅ SUCESSO] Pacote 'nftables' já está instalado"
fi

# Evita conflito com firewalld antes de habilitar o serviço
if ! systemctl is-active --quiet firewalld; then
  if ! systemctl is-enabled --quiet nftables; then
    echo "🔄 Habilitando e iniciando o serviço 'nftables'..."
    systemctl enable --now nftables && echo "[✅ SUCESSO] Serviço 'nftables' habilitado"
  else
    echo "[✅ SUCESSO] Serviço 'nftables' já está habilitado"
  fi
else
  echo "⚠️ AVISO: O serviço 'firewalld' está em execução. 'nftables' não será habilitado para evitar conflito"
fi

exit 0