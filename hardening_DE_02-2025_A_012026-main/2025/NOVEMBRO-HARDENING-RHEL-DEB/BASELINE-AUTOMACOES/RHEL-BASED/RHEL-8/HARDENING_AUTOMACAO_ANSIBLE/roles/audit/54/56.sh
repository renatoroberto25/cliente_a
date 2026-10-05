#!/usr/bin/env bash
echo "[56] Verificar se CBC está desabilitado na política de criptografia"

arquivo="/etc/crypto-policies/state/CURRENT.pol"

if grep -Piq '^\h*cipher@(lib|open)?ssh.*=\h*.*-CBC\b' "$arquivo"; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi