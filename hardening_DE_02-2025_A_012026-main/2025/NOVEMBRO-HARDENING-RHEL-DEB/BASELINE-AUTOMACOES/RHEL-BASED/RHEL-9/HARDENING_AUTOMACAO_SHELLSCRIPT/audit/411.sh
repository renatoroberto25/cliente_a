#!/usr/bin/env bash
echo -e "\n[135] Certifique-se de que o nftables esteja instalado"

# Verifica se o pacote nftables está instalado
if command -v rpm &>/dev/null; then
    if rpm -q nftables &>/dev/null; then
        echo "✅ [APROVADO]: Pacote 'nftables' está instalado."
    else
        echo "⚠️[REPROVADO]: Pacote 'nftables' não está instalado."
    fi
elif command -v dnf &>/dev/null; then
    if dnf list installed nftables &>/dev/null; then
        echo "✅ [APROVADO]: Pacote 'nftables' está instalado."
    else
        echo "⚠️[REPROVADO]: Pacote 'nftables' não está instalado."
    fi
else
    echo "⚠️ ERRO: Nenhum gerenciador de pacotes encontrado (rpm ou dnf)."
fi

exit 0