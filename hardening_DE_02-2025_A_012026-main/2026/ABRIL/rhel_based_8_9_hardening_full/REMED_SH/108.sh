#!/usr/bin/env bash
echo "[108] Remediação: Política de Criptografia TLS"
if command -v update-crypto-policies >/dev/null 2>&1; then
    CURRENT="$(update-crypto-policies --show 2>/dev/null)"

    if [ "$CURRENT" != "FUTURE" ]; then
        update-crypto-policies --set FUTURE
    fi
fi
echo "OK"
exit 0
