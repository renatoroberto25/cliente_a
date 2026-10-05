#!/usr/bin/env bash

echo -e "\n[190 - 191] Remediando configurações de histórico de senhas (pwhistory.conf)"

# --- 190 Ensure password history remember is configured ---
echo "## 190: Verificando parâmetro 'remember' ##"
if grep -Pi -- '^\h*remember\h*=\h*(2[4-9]|[3-9][0-9]|[1-9][0-9]{2,})\b' /etc/security/pwhistory.conf; then
  echo "  ✅ [APROVADO]: 'remember' configurado corretamente."
else
  echo "  ⚠️ [REPROVADO]: 'remember' ausente ou mal configurado. Corrigindo para 'remember = 24'."
  sed -i "/^\s*remember\s*=/s/^/# /" /etc/security/pwhistory.conf
  echo "remember = 24" >> /etc/security/pwhistory.conf
fi

# --- 191 Ensure password history is enforced for the root user ---
echo "## 191: Verificando 'enforce_for_root' ##"
if grep -Psiq '^\h*enforce_for_root\b' /etc/security/pwhistory.conf /etc/security/pwhistory.conf.d/*.conf; then
  echo "  ✅ [APROVADO]: 'enforce_for_root' já está presente."
else
  echo "  ⚠️ [REPROVADO]: 'enforce_for_root' ausente. Adicionando..."
  echo "enforce_for_root" >> /etc/security/pwhistory.conf
fi

echo -e "\n✅ Remediação concluída"