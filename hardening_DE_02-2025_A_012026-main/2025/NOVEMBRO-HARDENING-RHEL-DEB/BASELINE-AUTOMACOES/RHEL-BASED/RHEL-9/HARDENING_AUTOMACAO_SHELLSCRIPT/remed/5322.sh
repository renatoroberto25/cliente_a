#!/usr/bin/env bash

echo "[176] Habilitar pam_faillock nos arquivos PAM"

# Mapeamento de linhas esperadas por arquivo
declare -A linhas_pam_faillock=(
  ["password-auth"]="auth        required        pam_faillock.so preauth silent
auth        required        pam_faillock.so authfail
account     required        pam_faillock.so"
  ["system-auth"]="auth          required        pam_faillock.so preauth silent
auth          required        pam_faillock.so authfail
account       required        pam_faillock.so"
)

for arquivo in "${!linhas_pam_faillock[@]}"; do
  caminho="/etc/pam.d/$arquivo"

  echo " Verificando: $caminho"
  linhas_esperadas="${linhas_pam_faillock[$arquivo]}"

  while IFS= read -r linha; do
    if grep -Fxq "$linha" "$caminho"; then
      echo "✅ Já existe: $linha"
    else
      echo "⚠️ Adicionando: $linha"
      echo -e "\n# Adicionado via hardening – pam_faillock\n$linha" >> "$caminho"
    fi
  done <<< "$linhas_esperadas"
done

echo "✅ Remediação concluída para 176"
exit 0