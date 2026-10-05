#!/bin/bash

MODULE_FILE="/etc/crypto-policies/policies/modules/NO-SSHETM.pmod"
POLICY_UPDATE="DEFAULT:NO-SSHETM" # Alterado para apenas NO-SSHETM
EXPECTED_CONTENT="# Esta é uma subpolítica para desabilitar Encrypt then MAC\n# for the SSH protocol (libssh and OpenSSH)\netm@SSH = DISABLE_ETM\n"

if [[ ! -f "$MODULE_FILE" || "$(sudo cat "$MODULE_FILE")" != "$EXPECTED_CONTENT" ]]; then
  printf '%s\n' "# Esta é uma subpolítica para desabilitar Encrypt then MAC" "# for the SSH protocol (libssh and OpenSSH)" "etm@SSH = DISABLE_ETM" | sudo tee "$MODULE_FILE" > /dev/null
  echo "Módulo NO-SSHETM.pmod criado ou corrigido."
fi

sudo update-crypto-policies --set "$POLICY_UPDATE"
echo "Política atualizada para $POLICY_UPDATE."