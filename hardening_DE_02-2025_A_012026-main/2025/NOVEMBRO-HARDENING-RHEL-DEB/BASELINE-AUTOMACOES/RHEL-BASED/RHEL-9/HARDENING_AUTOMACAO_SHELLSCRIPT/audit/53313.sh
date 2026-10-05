#!/usr/bin/env bash

echo -e "\n[182] Verificar se existe bloqueio de senha para o root (faillock)"

# --- Verifica configuração no /etc/security/faillock.conf ---
echo "--- Verificando faillock.conf ---"

resultado_faillock=$(grep -Pi '^\s*(even_deny_root|root_unlock_time\s*=\s*\d+)' /etc/security/faillock.conf)

if echo "$resultado_faillock" | grep -q "even_deny_root"; then
  echo "✅ [APROVADO]: even_deny_root presente em faillock.conf"
elif echo "$resultado_faillock" | grep -q "root_unlock_time"; then
  valor=$(echo "$resultado_faillock" | grep -Po 'root_unlock_time\s*=\s*\K\d+')
  if [ "$valor" -ge 60 ]; then
    echo "✅ [APROVADO]: root_unlock_time >= 60 em faillock.conf"
  else
    echo "⚠️ [REPROVADO]: root_unlock_time presente, mas com valor inferior a 60 segundos"
  fi
else
  echo "⚠️ [REPROVADO]: Nem even_deny_root nem root_unlock_time encontrados"
fi

# --- Verificação complementar nos arquivos PAM ---
echo "--- Verificando PAM (/etc/pam.d/system-auth e password-auth) ---"
echo "    (⚠️ Apenas complementar, considerar prioritariamente faillock.conf)"

resultado_pam=$(grep -Pi '^\s*auth\s+.*pam_faillock\.so\s+.*root_unlock_time\s*=\s*([1-5]?[0-9])\b' /etc/pam.d/system-auth /etc/pam.d/password-auth 2>/dev/null)

if [ -n "$resultado_pam" ]; then
  echo "⚠️ [REPROVADO]: root_unlock_time < 60 encontrado nos arquivos PAM:"
  echo "$resultado_pam"
else
  echo "✅ [APROVADO]: Nenhuma configuração incorreta de root_unlock_time nos arquivos PAM"
fi

echo "✅ Auditoria finalizada"
exit 0