#!/usr/bin/env bash
echo "[57] Verificar se MACs fracos (inferiores a 128 bits) estão desabilitados"

arquivo="/etc/crypto-policies/state/CURRENT.pol"

if grep -Pi -- '^\h*mac\h*=\h*([^#\n\r]+)?-64\b' "$arquivo" &>/dev/null; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi