#!/usr/bin/env bash

echo -e "\n[141] Remediação – Política padrão DROP no nftables"

echo "⚠️ AVISO: Antes de aplicar DROP, certifique-se de permitir conexões essenciais como SSH ou DNS, senão poderá perder o acesso remoto."

# Verifica se nftables está ativo e habilitado
if systemctl is-enabled --quiet nftables && systemctl is-active --quiet nftables; then
    echo "✅ Serviço 'nftables' está ativo e habilitado."

    # Garante existência da tabela e cadeias
    echo "🔧 Verificando estrutura básica..."
    nft list tables | grep -q "inet filter" || { nft add table inet filter && echo "✅ Tabela 'inet filter' criada."; }
    for chain in input forward output; do
        if ! nft list table inet filter | grep -q "chain $chain"; then
            nft add chain inet filter "$chain" "{ type filter hook $chain priority 0 ; }" && echo "✅ Cadeia '$chain' criada."
        fi
    done

    # Aplica política DROP apenas se ainda não estiver aplicada
    echo "🔧 Aplicando política DROP..."
    for chain in input forward output; do
        nft list chain inet filter "$chain" | grep -q "policy drop" || {
            nft chain inet filter "$chain" { policy drop ; } && echo "✅ DROP aplicado em '$chain'."
        }
    done

    # AVISO: o usuário deve garantir exceções manualmente
    echo "⚠️ Atenção: Adicione exceções para SSH e ICMP conforme necessário:"
    echo "   ➤ nft add rule inet filter input ct state established,related accept"
    echo "   ➤ nft add rule inet filter input ip protocol tcp dport 22 accept"
    echo "   ➤ nft add rule inet filter input ip protocol icmp accept"

    # Salva persistência
    nft list ruleset > /etc/sysconfig/nftables.conf && echo "✅ Regras salvas para persistência."

else
    echo "❌ Falha: O serviço 'nftables' não está ativo ou habilitado."
    exit 1
fi

echo "[ICMP] Garantir DROP para timestamp-request e timestamp-reply"

# 1. Garantir tabela e chain
nft list table inet filter >/dev/null 2>&1 || nft add table inet filter
nft list chain inet filter input >/dev/null 2>&1 \
  || nft add chain inet filter input { type filter hook input priority 0\; }

# 2. Remover TODAS as instâncias antigas
nft --handle list chain inet filter input \
 | grep -Ei 'icmp[[:space:]]+type[[:space:]]+timestamp-(request|reply)' \
 | awk '{print $NF}' \
 | sed 's/;$//' \
 | xargs -r -I{} nft delete rule inet filter input handle {}

# 3. Criar regras definitivas
nft add rule inet filter input icmp type timestamp-request drop
nft add rule inet filter input icmp type timestamp-reply drop

# 4. Persistência
nft list ruleset >/etc/nftables.conf