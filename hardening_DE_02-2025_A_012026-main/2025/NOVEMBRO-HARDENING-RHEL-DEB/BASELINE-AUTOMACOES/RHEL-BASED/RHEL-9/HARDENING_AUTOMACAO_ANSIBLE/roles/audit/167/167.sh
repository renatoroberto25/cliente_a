#!/usr/bin/env bash

FILE="/etc/crypto-policies/state/CURRENT.pol"

echo -e "\n 61 – Verificar se EtM (Encrypt-then-MAC) está desabilitado para SSH"

if grep -Psiq -- '^\h*etm@(libssh|openssh-client|openssh-server)\s*=\s*DISABLE_ETM\b' "$FILE"; then
   echo -e "\n✅ [APROVADO]: EtM está desabilitado para SSH."
else
   echo -e "\n⚠️  [REPROVADO]: EtM não está desabilitado para SSH."
   echo -e "\n❗ Esperado:"
   echo "   etm@(libssh|openssh-client|openssh-server) = DISABLE_ETM"
   echo -e "📄 Verifique o conteúdo de: $FILE"
fi

exit 0
