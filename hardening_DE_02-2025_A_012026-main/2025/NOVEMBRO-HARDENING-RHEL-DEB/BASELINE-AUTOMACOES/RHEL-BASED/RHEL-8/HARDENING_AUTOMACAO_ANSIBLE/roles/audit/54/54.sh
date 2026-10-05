#!/usr/bin/env bash
echo "[54] Verificar se a política de criptografia não está definida como LEGACY"
grep -q '^LEGACY$' /etc/crypto-policies/config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"