#!/bin/bash

MODULE_FILE="/etc/crypto-policies/policies/modules/NO-WEAKMAC.pmod"
POLICY_UPDATE="DEFAULT:NO-SHA1:NO-WEAKMAC"
EXPECTED_CONTENT="# Esta é uma subpolítica para desabilitar macs fracos\nmac = -*-64\n"

if [[ ! -f "$MODULE_FILE" || "$(sudo cat "$MODULE_FILE")" != "$EXPECTED_CONTENT" ]]; then
  printf '%s\n' "# Esta é uma subpolítica para desabilitar macs fracos" "mac = -*-64" | sudo tee "$MODULE_FILE" > /dev/null
  echo "Módulo NO-WEAKMAC.pmod criado ou corrigido."
fi

sudo update-crypto-policies --set "$POLICY_UPDATE"
echo "Política atualizada para $POLICY_UPDATE."