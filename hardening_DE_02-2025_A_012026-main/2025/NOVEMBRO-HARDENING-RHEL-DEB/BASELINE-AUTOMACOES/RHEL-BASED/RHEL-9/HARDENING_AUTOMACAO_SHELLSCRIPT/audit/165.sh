#!/usr/bin/env bash

echo -e "\n 59 – Verificar se o uso de CBC (Cipher Block Chaining) está desativado para SSH"

arquivo="/etc/crypto-policies/state/CURRENT.pol"

if grep -Piq '^\h*cipher@(lib|open)?ssh.*=\h*.*-CBC\b' "$arquivo"; then
   echo -e "\n⚠️  [REPROVADO]: CBC ainda está habilitado nas configurações específicas de SSH."
else
   echo -e "\n✅ [APROVADO]: CBC está desativado para SSH."
fi

echo -e "\n📄 Trechos relevantes de $arquivo:"
grep -Pi '^\h*cipher.*=' "$arquivo"
