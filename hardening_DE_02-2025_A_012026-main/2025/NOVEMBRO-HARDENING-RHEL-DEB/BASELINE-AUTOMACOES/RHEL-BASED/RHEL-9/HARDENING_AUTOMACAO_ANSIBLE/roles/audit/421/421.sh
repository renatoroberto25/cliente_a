#!/usr/bin/env bash

echo -e "\n[137] Certifique-se de que o firewalld bloqueie serviços e portas desnecessários"

if systemctl is-enabled firewalld.service &>/dev/null; then
    echo "✅ [APROVADO]: O serviço 'firewalld' está habilitado."

    zona_ativa=$(firewall-cmd --get-active-zones | awk 'NR==1 {print $1}')
    if [ -n "$zona_ativa" ]; then
        echo "ℹ️ Zona ativa detectada: $zona_ativa"
        configuracoes=$(firewall-cmd --list-all --zone="$zona_ativa" | grep -E 'services:|ports:')

        if [ -n "$configuracoes" ]; then
            echo "[⚠️ AVISO]: Serviços e/ou portas estão abertos na zona '$zona_ativa':"
            echo "$configuracoes"
            echo "⚠️ VERIFIQUE POLÍTICAS LOCAIS: ajuste conforme necessário."
        else
            echo "✅ [APROVADO]: Nenhum serviço ou porta extra configurado na zona ativa."
        fi
    else
        echo "⚠️[REPROVADO]: Nenhuma zona ativa detectada no firewalld."
    fi
else
    echo "⚠️[REPROVADO]: O serviço 'firewalld' não está habilitado."
fi