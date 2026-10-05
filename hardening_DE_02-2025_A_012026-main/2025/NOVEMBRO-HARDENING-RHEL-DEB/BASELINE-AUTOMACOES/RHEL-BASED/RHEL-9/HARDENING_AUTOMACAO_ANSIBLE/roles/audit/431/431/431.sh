#!/usr/bin/env bash
echo -e "\n[139] Certifique-se de que as cadeias base do nftables existam"

# Verifica se o nftables está instalado
if ! command -v nft &>/dev/null; then
    echo "❌ [REPROVADO]: nftables não está instalado ou não está no PATH."
    exit 0
fi

echo "✅ [APROVADO]: nftables está instalado."

# Verifica se as cadeias base (input, forward, output) existem
for cadeia in input forward output; do
    if nft list ruleset | grep -i "hook $cadeia" > /dev/null; then
        echo "✅ [APROVADO]: Cadeia base '$cadeia' encontrada."
    else
        echo "⚠️ [REPROVADO]: Cadeia base '$cadeia' **não** encontrada."
    fi
done