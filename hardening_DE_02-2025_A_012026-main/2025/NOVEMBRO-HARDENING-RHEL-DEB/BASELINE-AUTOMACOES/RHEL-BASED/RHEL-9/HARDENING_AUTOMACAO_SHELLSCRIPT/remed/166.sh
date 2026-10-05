#!/bin/bash

MODULE_FILE="/etc/crypto-policies/policies/modules/NO-SSHCHACHA20.pmod"
POLICY_UPDATE="DEFAULT:NO-SSHCHACHA20" # Alterado para apenas NO-SSHCHACHA20
EXPECTED_CONTENT="# Esta é uma subpolítica para desabilitar the chacha20-poly1305 ciphers\n# for the SSH protocol (libssh and OpenSSH)\ncipher@SSH = -CHACHA20-POLY1305\n"

if [[ ! -f "$MODULE_FILE" || "$(sudo cat "$MODULE_FILE")" != "$EXPECTED_CONTENT" ]]; then
  printf '%s\n' "# Esta é uma subpolítica para desabilitar the chacha20-poly1305 ciphers" "# for the SSH protocol (libssh and OpenSSH)" "cipher@SSH = -CHACHA20-POLY1305" | sudo tee "$MODULE_FILE" > /dev/null
  echo "Módulo NO-SSHCHACHA20.pmod criado ou corrigido."
fi

sudo update-crypto-policies --set "$POLICY_UPDATE"
echo "Política atualizada para $POLICY_UPDATE."