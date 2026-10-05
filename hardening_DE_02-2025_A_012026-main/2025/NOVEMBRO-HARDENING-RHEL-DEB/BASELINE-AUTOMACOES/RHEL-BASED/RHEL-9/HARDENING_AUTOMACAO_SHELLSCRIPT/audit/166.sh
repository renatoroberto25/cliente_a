#!/usr/bin/env bash

ARQ="/etc/crypto-policies/state/CURRENT.pol"

echo -e "\n [60] Verificar se chacha20-poly1305 está desativado para SSH"

if grep -Piq '^\h*cipher(@(lib|open)ssh(-server|-client)?)?\h*=\h*.*\bCHACHA20-POLY1305\b' "$ARQ"; then
    echo -e "⚠️  [REPROVADO]: chacha20-poly1305 ainda está ativo.\n"
    echo "❗ chacha20-poly1305 está habilitado nas políticas de SSH."
else
    echo -e "✅ [APROVADO]: chacha20-poly1305 está desativado para SSH."
fi

exit 0
