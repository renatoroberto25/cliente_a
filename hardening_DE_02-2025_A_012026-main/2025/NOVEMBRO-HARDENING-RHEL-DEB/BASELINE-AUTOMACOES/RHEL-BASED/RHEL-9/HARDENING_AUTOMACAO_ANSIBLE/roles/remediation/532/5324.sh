#!/usr/bin/env bash

echo -e "\n[178] Certificar que o módulo pam_pwhistory está habilitado"

linha_pam_pwhistory="password required pam_pwhistory.so use_authtok"

for arquivo in /etc/pam.d/password-auth /etc/pam.d/system-auth; do
  if [[ ! -f "$arquivo" ]]; then
    echo "[❗] Arquivo $arquivo não encontrado. Verificação encerrada para este caminho."
    continue
  fi

  if grep -qF "$linha_pam_pwhistory" "$arquivo"; then
    echo "✅ [APROVADO]: pam_pwhistory.so já configurado em $arquivo."
  else
    echo "# Adicionado via hardening - pam_pwhistory" >> "$arquivo"
    echo "$linha_pam_pwhistory" >> "$arquivo"
    echo "✅ [CORRIGIDO]: pam_pwhistory.so adicionado a $arquivo."
  fi
done

exit 0