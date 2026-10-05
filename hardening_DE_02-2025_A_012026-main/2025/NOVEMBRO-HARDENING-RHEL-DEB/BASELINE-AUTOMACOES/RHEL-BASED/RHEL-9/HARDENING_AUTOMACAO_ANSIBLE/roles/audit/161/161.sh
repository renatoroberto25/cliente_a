#!/usr/bin/env bash

echo -e "\n 55 – Verificar se a política de criptografia do sistema não está definida como LEGACY"

arquivo="/etc/crypto-policies/config"

if grep -Piq '^\h*LEGACY\b' "$arquivo"; then
   echo -e "\n⚠️  [REPROVADO]: Política de criptografia está definida como LEGACY."
else
   echo -e "\n✅ [APROVADO]: Política de criptografia não está definida como LEGACY."
fi

echo -e "\n📄 Conteúdo atual de $arquivo:"
cat "$arquivo"

echo -e "\nℹ️ FIPS pode ser aplicado para reforçar a criptografia, se necessário."
fips-mode-setup --check
