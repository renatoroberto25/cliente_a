#!/bin/bash

MODULE_FILE="/etc/crypto-policies/policies/modules/NO-SHA1.pmod"
POLICY_UPDATE="DEFAULT:NO-SHA1" # Alterado para apenas NO-SHA1
EXPECTED_CONTENT="# Esta e uma subpolítica que elimina o suporte de hash e assinatura SHA1\nhash = -SHA1\nsign = -*-SHA1\nsha1_in_certs = 0\n"

if [[ ! -f "$MODULE_FILE" || "$(sudo cat "$MODULE_FILE")" != "$EXPECTED_CONTENT" ]]; then
  printf '%s\n' "# Esta e uma subpolítica que elimina o suporte de hash e assinatura SHA1" "hash = -SHA1" "sign = -*-SHA1" "sha1_in_certs = 0" | sudo tee "$MODULE_FILE" > /dev/null
  echo "Módulo NO-SHA1.pmod criado ou corrigido."
fi

sudo update-crypto-policies --set "$POLICY_UPDATE"
echo "Política atualizada para $POLICY_UPDATE."