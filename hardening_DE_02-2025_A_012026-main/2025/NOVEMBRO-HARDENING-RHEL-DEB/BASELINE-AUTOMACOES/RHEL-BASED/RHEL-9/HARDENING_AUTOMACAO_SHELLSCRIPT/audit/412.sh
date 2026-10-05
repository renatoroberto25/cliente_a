#!/usr/bin/env bash

echo -e "\n[136] Certifique-se de que um único utilitário de configuração de firewall esteja em uso"

fwd_status=""
nft_status=""
fwutil_status=""
resultado_pass=()
resultado_fail=()

# Status do FirewallD
if rpm -q firewalld &>/dev/null; then
    fwd_status="$(systemctl is-enabled firewalld.service 2>/dev/null):$(systemctl is-active firewalld.service 2>/dev/null)"
else
    fwd_status="ausente"
fi

# Status do nftables
if rpm -q nftables &>/dev/null; then
    nft_status="$(systemctl is-enabled nftables.service 2>/dev/null):$(systemctl is-active nftables.service 2>/dev/null)"
else
    nft_status="ausente"
fi

fwutil_status="${fwd_status}:${nft_status}"

case "$fwutil_status" in
    enabled:active:masked:inactive | enabled:active:disabled:inactive)
        resultado_pass+=("FirewallD habilitado e ativo. NFTables desativado/masked.")
        ;;
    masked:inactive:enabled:active | disabled:inactive:enabled:active)
        resultado_pass+=("NFTables habilitado e ativo. FirewallD desativado/masked.")
        ;;
    enabled:active:enabled:active)
        resultado_fail+=("Ambos os firewalls estão ativos. Configure apenas um: **FirewallD** ou **NFTables**.")
        ;;
    enabled:*:enabled:*)
        resultado_fail+=("Ambos os firewalls estão habilitados. Configure apenas um.")
        ;;
    *:active:*:active)
        resultado_fail+=("Ambos os firewalls estão ativos. Configure apenas um.")
        ;;
    ausente:enabled:active)
        resultado_pass+=("NFTables ativo. FirewallD não instalado.")
        ;;
    ausente:ausente)
        resultado_fail+=("Nenhum firewall instalado. Configure pelo menos um: **FirewallD** ou **NFTables**.")
        ;;
    *:ausente)
        resultado_fail+=("NFTables não instalado. Instale e configure apenas um firewall.")
        ;;
    *)
        resultado_fail+=("Estado dos firewalls indefinido. Verifique manualmente.")
        ;;
esac

# Exibir resultado
if [ "${#resultado_fail[@]}" -eq 0 ]; then
    echo "✅ [APROVADO]:"
    printf '%s\n' "${resultado_pass[@]}"
else
    echo "⚠️[REPROVADO]:"
    printf '%s\n' "${resultado_fail[@]}"
    [ "${#resultado_pass[@]}" -gt 0 ] && {
        echo -e "\nℹ️ Detalhes adicionais:"
        printf '%s\n' "${resultado_pass[@]}"
    }
fi
exit 0 