#!/usr/bin/env bash

echo -e "\n[181] Verificar se o tempo de desbloqueio de senha está configurado corretamente"

# --- Verificação do arquivo /etc/security/faillock.conf ---
echo "--- Verificando /etc/security/faillock.conf ---"

if grep -Pq '^\h*unlock_time\h*=\h*(0|9[0-9][0-9]|[1-9][0-9]{3,})\b' /etc/security/faillock.conf; then
  echo "✅ [APROVADO]: unlock_time está configurado como 0 ou >= 900 em faillock.conf"
else
  echo "⚠️ [REPROVADO]: unlock_time não está configurado corretamente em faillock.conf"
fi

# --- Verificação de unlock_time com valor inadequado nos arquivos PAM ---
echo "--- Verificando parâmetros incorretos nos arquivos PAM ---"

resultado_pam=$(grep -Pi -- '\bpam_faillock\.so\b.*\bunlock_time\s*=\s*(1?[0-9]{1,2}|[1-8][0-9]{2})\b' /etc/pam.d/system-auth /etc/pam.d/password-auth 2>/dev/null)

if [[ -z "$resultado_pam" ]]; then
  echo "✅ [APROVADO]: Nenhuma configuração inadequada de unlock_time nos arquivos PAM"
else
  echo "⚠️ [REPROVADO]: Encontradas configurações inadequadas de unlock_time nos arquivos PAM:"
  echo "$resultado_pam"
fi

echo "✅ Auditoria finalizada"
exit 0