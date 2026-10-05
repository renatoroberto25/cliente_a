#!/usr/bin/env bash

echo " Auditoria: HITSS 49 - 50 – Verificação de senha no GRUB2"

# 49 – Verificar se existe arquivo de senha do GRUB2
l_grub_password_file="$(find /boot -type f -name 'user.cfg' ! -empty 2>/dev/null)"

if [[ -f "$l_grub_password_file" ]]; then
  echo "✅ [49] Arquivo de senha do GRUB2 encontrado: $l_grub_password_file"

  # 50 – Verificar se a linha GRUB2_APROVADOWORD está presente
  hash=$(grep -E '^\s*GRUB2_APROVADOWORD=' "$l_grub_password_file" | awk -F'=' '{gsub(/"/, "", $2); print $2}')
  
  if [[ -n "$hash" ]]; then
    echo "✅ [50] Hash da senha GRUB2 encontrado: $hash"
  else
    echo "⚠️ [50] Linha GRUB2_APROVADOWORD não encontrada no arquivo"
  fi
else
  echo "⚠️ [49] Nenhum arquivo de senha do GRUB2 encontrado ou está vazio"
fi

exit 0
