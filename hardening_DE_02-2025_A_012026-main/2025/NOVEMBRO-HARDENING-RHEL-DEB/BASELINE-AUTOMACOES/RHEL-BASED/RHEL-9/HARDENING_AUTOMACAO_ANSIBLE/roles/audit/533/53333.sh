#!/usr/bin/env bash

echo -e "\n[192] Verificar se pam_pwhistory inclui 'use_authtok'"

# Verifica se pam_pwhistory.so e use_authtok estão presentes corretamente
if grep -Pq -- '^\h*password\h+\S+\h+pam_pwhistory\.so\h+.*\buse_authtok\b' /etc/pam.d/password-auth /etc/pam.d/system-auth; then
  echo "  ✅ [APROVADO]: pam_pwhistory.so com 'use_authtok' corretamente configurado nos arquivos PAM."
else
  echo "  ⚠️ [REPROVADO]: 'use_authtok' não configurado com pam_pwhistory.so. Verifique os arquivos /etc/pam.d/password-auth e system-auth."
fi