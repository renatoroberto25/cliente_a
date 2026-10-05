#!/usr/bin/env bash
set -u

echo "[108] Remediacao: politica de criptografia TLS"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para avaliar remediacoes"
    exit 0
fi

echo "[108] TLS minimo 1.2/1.3"
if ! command -v update-crypto-policies >/dev/null 2>&1; then
    echo "SKIP: update-crypto-policies nao disponivel neste sistema"
elif update-crypto-policies --show 2>/dev/null | grep -qx FUTURE; then
    echo "OK: politica de criptografia ja esta em FUTURE"
else
    echo "SKIP: alterar crypto policy para FUTURE e global e pode quebrar integracoes TLS legadas"
fi

echo "OK"
exit 0
