#!/usr/bin/env bash

echo "[176] Verificar se o módulo pam_faillock.so está habilitado"

arquivos=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
achou=0

for arquivo in "${arquivos[@]}"; do
  if grep -q '\bpam_faillock.so\b' "$arquivo"; then
    echo "✅ pam_faillock.so encontrado em $arquivo"
    achou=1
  fi
done

if [[ $achou -eq 0 ]]; then
  echo "⚠️ pam_faillock.so não encontrado nos arquivos padrão do PAM"
fi

exit 0