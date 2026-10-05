#!/usr/bin/env bash

echo -e "\n[139] Remediação – Criar cadeias base no nftables"

# Verifica se o nft está disponível
if ! command -v nft &>/dev/null; then
    echo "❌ Falha: nftables não está instalado ou no PATH."
    exit 1
fi

echo "✅ nftables está disponível no sistema."

TABLE="filter"
CHAINS=("input" "forward" "output")
FWD_ACTIVE=false

# Verifica se firewalld está ativo
if systemctl is-active --quiet firewalld; then
    echo "⚠️ ALERTA: firewalld está ativo e pode gerenciar regras de firewall."
    FWD_ACTIVE=true
fi

# Cria a tabela inet filter se não existir
if ! nft list tables | grep -q "inet $TABLE"; then
    echo "🔧 Criando tabela inet $TABLE..."
    if nft add table inet $TABLE; then
        echo "✅ Tabela 'inet $TABLE' criada."
    else
        echo "❌ Falha ao criar tabela 'inet $TABLE'."
        exit 1
    fi
else
    echo "✅ Tabela 'inet $TABLE' já existe."
fi

# Função para verificar se a cadeia está gerenciada pelo firewalld
is_managed_by_firewalld() {
    firewall-cmd --info-zone=public 2>/dev/null | grep -iq "$1"
}

# Cria as cadeias se necessário
for chain in "${CHAINS[@]}"; do
    if $FWD_ACTIVE && is_managed_by_firewalld "$chain"; then
        echo "⚠️ Cadeia '$chain' é gerenciada pelo firewalld – não será modificada."
        continue
    fi

    if ! nft list ruleset | grep -iq "hook $chain"; then
        echo "🔧 Criando cadeia '$chain' com hook '$chain'..."
        if nft add chain inet $TABLE $chain "{ type filter hook $chain priority 0; policy accept; }"; then
            echo "✅ Cadeia '$chain' criada com sucesso."
        else
            echo "❌ Falha ao criar cadeia '$chain'."
        fi
    else
        echo "✅ Cadeia '$chain' já existe."
    fi
done