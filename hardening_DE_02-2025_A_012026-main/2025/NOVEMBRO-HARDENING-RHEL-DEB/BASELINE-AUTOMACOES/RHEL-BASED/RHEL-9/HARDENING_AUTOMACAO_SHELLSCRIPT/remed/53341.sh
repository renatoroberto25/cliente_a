#!/usr/bin/env bash

echo -e "\n[193 - 196] Ajustes em pam_unix – parâmetros críticos"

arquivos=(/etc/pam.d/password-auth /etc/pam.d/system-auth)
data=$(date +%Y%m%d%H%M%S)

for arq in "${arquivos[@]}"; do
  [ -f "$arq" ] || continue
  cp "$arq" "${arq}.bak.${data}" && echo "🗂️ Backup criado: ${arq}.bak.${data}"

  # 193 – Remover nullok
  if grep -qP '\bnullok\b' "$arq"; then
    sed -Ei 's/(pam_unix\.so.*)\bnullok\b/\1/' "$arq"
    echo "✅ 'nullok' removido de $arq"
  else
    echo "✅ [APROVADO]: 'nullok' não presente em $arq"
  fi

  # 194 – Remover remember
  if grep -qP '\bremember=[0-9]+' "$arq"; then
    sed -Ei 's/(pam_unix\.so.*)\bremember=[0-9]+\b/\1/' "$arq"
    echo "✅ 'remember=n' removido de $arq"
  else
    echo "✅ [APROVADO]: 'remember=n' não presente em $arq"
  fi

  # 195 – Garantir hash forte (sha512 ou yescrypt)
  if grep -Pq 'pam_unix\.so(?!.*(sha512|yescrypt))' "$arq"; then
    sed -Ei '/pam_unix\.so/ { /sha512|yescrypt/! s/(pam_unix\.so.*)/\1 sha512/ }' "$arq"
    echo "✅ Hash forte 'sha512' garantido em $arq"
  else
    echo "✅ [APROVADO]: Hash forte já presente em $arq"
  fi

  # 196 – Garantir uso de 'use_authtok'
  if grep -Pq 'pam_unix\.so(?!.*use_authtok)' "$arq"; then
    sed -Ei '/pam_unix\.so/ { /use_authtok/! s/(pam_unix\.so.*)/\1 use_authtok/ }' "$arq"
    echo "✅ Parâmetro 'use_authtok' garantido em $arq"
  else
    echo "✅ [APROVADO]: 'use_authtok' já presente em $arq"
  fi
done

exit 0