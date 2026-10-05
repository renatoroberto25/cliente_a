#!/usr/bin/env bash

echo "[178] Verificar se o módulo pam_pwhistory.so está habilitado"

modulo="pam_pwhistory.so"
arquivos=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
achou=0

for arq in "${arquivos[@]}"; do
  if grep -q "\b$modulo\b" "$arq"; then
    echo "✅ $modulo encontrado em $arq"
    achou=1
  fi
done

if [[ $achou -eq 0 ]]; then
  echo "⚠️ $modulo não encontrado nos arquivos PAM"
fi

echo -e "\n✅ Auditoria finalizada"
exit 0