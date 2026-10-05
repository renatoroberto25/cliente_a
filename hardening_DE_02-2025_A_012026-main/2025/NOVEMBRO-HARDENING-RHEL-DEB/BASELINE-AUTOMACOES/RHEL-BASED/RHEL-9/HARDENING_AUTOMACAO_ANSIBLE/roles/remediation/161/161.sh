#!/usr/bin/env bash

# Definir a política de criptografia para DEFAULT
echo "Definir a política de criptografia para DEFAULT"
update-crypto-policies --set DEFAULT

# Tornar a política de criptografia ativa
echo "Ativar a criptografia"
update-crypto-policies
#Validar config
cat /etc/crypto-policies/config
echo "Política de criptografia do sistema definida para DEFAULT e ativada."
