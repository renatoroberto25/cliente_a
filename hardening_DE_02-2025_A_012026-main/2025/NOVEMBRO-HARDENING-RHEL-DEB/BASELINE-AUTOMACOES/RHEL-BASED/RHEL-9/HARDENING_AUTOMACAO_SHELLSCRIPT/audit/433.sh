#!/usr/bin/env bash
echo -e "\n[141] Garantir a política de firewall de negação padrão do nftables"

# Verifica se o serviço nftables está habilitado e ativo
if systemctl is-enabled --quiet nftables && systemctl is-active --quiet nftables; then
    echo "✅ [APROVADO]: Serviço 'nftables' está ativo e habilitado."

    # Verifica política da cadeia INPUT
    if nft list ruleset | grep -Pq 'hook input .* policy drop'; then
        echo "✅ [APROVADO]: Política da cadeia INPUT está configurada como DROP."
    else
        echo "⚠️ [REPROVADO]: Política da cadeia INPUT NÃO está configurada como DROP."
    fi

    # Verifica política da cadeia FORWARD
    if nft list ruleset | grep -Pq 'hook forward .* policy drop'; then
        echo "✅ [APROVADO]: Política da cadeia FORWARD está configurada como DROP."
    else
        echo "⚠️ [REPROVADO]: Política da cadeia FORWARD NÃO está configurada como DROP."
    fi
else
    echo "⚠️ [REPROVADO]: Serviço 'nftables' não está ativo ou habilitado. Auditoria não realizada."
fi

echo -e "\n[ICMP] Verifique se timestamp-request está configurado para drop"
( nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-request[[:space:]]+drop' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[ICMP] Verifique se timestamp-reply está configurado para drop"
( nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-reply[[:space:]]+drop' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

