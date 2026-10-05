#!/bin/bash

MODULE_FILE="/etc/crypto-policies/policies/modules/NO-SSHCBC.pmod"
POLICY_UPDATE="DEFAULT:NO-SSHCBC" # Alterado para apenas NO-SSHCBC
EXPECTED_CONTENT="# Esta é uma subpolítica para desabilitar all CBC mode ciphers\n# for the SSH protocol (libssh and OpenSSH)\ncipher@SSH = -*-CBC\n"

if [[ ! -f "$MODULE_FILE" || "$(sudo cat "$MODULE_FILE")" != "$EXPECTED_CONTENT" ]]; then
  printf '%s\n' "# Esta é uma subpolítica para desabilitar all CBC mode ciphers" "# for the SSH protocol (libssh and OpenSSH)" "cipher@SSH = -*-CBC" | sudo tee "$MODULE_FILE" > /dev/null
  echo "Módulo NO-SSHCBC.pmod criado ou corrigido."
fi

sudo update-crypto-policies --set "$POLICY_UPDATE"
echo "Política atualizada para $POLICY_UPDATE."