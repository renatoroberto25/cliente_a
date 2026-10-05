#!/usr/bin/env bash

# Validar config
echo "Conteúdo da config no sshd:"
grep -v '^#' /etc/sysconfig/sshd

# Alterar config
echo "Removendo a configuração se ela existir:"
sed -ri "s/^\s*(CRYPTO_POLICY\s*=.*)$/# \1/" /etc/sysconfig/sshd

# Recarregar as configurações com a alteração
echo "Reload no sshd"

