#!/usr/bin/env bash
echo -e "\n[140] Certifique-se de que as conexões estabelecidas do nftables estejam configuradas"

# Verifica se o serviço nftables está ativo e habilitado
if systemctl is-enabled nftables &>/dev/null && systemctl is-active nftables &>/dev/null; then
    echo "✅ [APROVADO]: Serviço 'nftables' está ativo e habilitado."

    # Verifica se há regra para conexões estabelecidas
    if nft list ruleset | grep -qE 'ct state (established|related) accept'; then
        echo "✅ [APROVADO]: Regras para conexões estabelecidas/relacionadas estão presentes."
    else
        echo "⚠️ [REPROVADO]: Conexões estabelecidas/relacionadas não estão definidas nas regras do nftables."
    fi
else
    echo "⚠️ [REPROVADO]: Serviço 'nftables' não está ativo ou habilitado."
fi