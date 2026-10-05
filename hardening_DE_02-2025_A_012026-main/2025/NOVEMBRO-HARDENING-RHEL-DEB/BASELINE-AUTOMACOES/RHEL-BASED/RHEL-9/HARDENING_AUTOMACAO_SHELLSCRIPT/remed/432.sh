#!/usr/bin/env bash

echo -e "\n[140] Remediação – Configurar conexões estabelecidas no nftables"

# Verifica se o nftables está instalado
if ! command -v nft &>/dev/null; then
    echo "❌ Falha: nftables não está instalado."
    exit 1
fi

# Habilita e inicia o serviço, se necessário
if ! systemctl is-enabled --quiet nftables; then
    echo "🔄 Habilitando o serviço 'nftables'..."
    systemctl enable --now nftables && echo "✅ Serviço 'nftables' habilitado e iniciado."
else
    echo "✅ Serviço 'nftables' já está habilitado."
fi

# Confirma se está ativo
if systemctl is-active --quiet nftables; then
    echo "✅ Serviço 'nftables' está ativo."

    # Adiciona regras para conexões estabelecidas (IPv4)
    echo "🔧 Adicionando regras para conexões estabelecidas..."
    nft add rule inet filter input ct state established accept 2>/dev/null && echo "✅ Regra aplicada: ct state established accept"
    
    # Salva regras para persistência
    nft list ruleset > /etc/sysconfig/nftables.conf && echo "✅ Regras salvas em /etc/sysconfig/nftables.conf"
else
    echo "❌ Falha: serviço 'nftables' não está ativo. Regras não aplicadas."
    exit 1
fi