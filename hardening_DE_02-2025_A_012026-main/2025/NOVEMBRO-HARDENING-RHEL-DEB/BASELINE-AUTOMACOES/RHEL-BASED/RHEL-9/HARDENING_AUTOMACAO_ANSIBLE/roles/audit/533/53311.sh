#!/usr/bin/env bash

echo -e "\n[180] Verificar se está configurado o bloqueio após falhas de senha"

# --- Verificação do arquivo /etc/security/faillock.conf ---
arquivo="/etc/security/faillock.conf"
parametro="deny"

echo "--- Verificando parâmetro '$parametro' em $arquivo ---"

if [[ -f "$arquivo" ]]; then
  valor=$(grep -Pi -- "^\h*${parametro}\h*=\h*[0-9]+" "$arquivo" | awk -F= '{gsub(/ /,"",$2); print $2}' | head -n1)

  if [[ -n "$valor" && "$valor" -le 5 ]]; then
    echo "✅ [APROVADO]: $parametro=$valor definido corretamente em $arquivo"
  elif [[ -n "$valor" ]]; then
    echo "⚠️ [REPROVADO]: $parametro=$valor definido acima do permitido em $arquivo"
  else
    echo "⚠️ [REPROVADO]: Parâmetro $parametro não definido em $arquivo"
  fi
else
  echo "❗ Arquivo $arquivo não encontrado"
fi

# --- Verificação do parâmetro deny nos arquivos PAM ---
echo "--- Verificando presença incorreta de 'deny' nos arquivos PAM ---"

resultado_pam=$(grep -Pi -- '\bpam_faillock\.so\b.*\bdeny\s*=\s*(0|[6-9]|[1-9][0-9]+)' /etc/pam.d/system-auth /etc/pam.d/password-auth 2>/dev/null)

if [[ -z "$resultado_pam" ]]; then
  echo "✅ [APROVADO]: Nenhuma configuração incorreta de 'deny' nos arquivos PAM"
else
  echo "⚠️ [REPROVADO]: Encontrado parâmetro 'deny' inadequado nos arquivos PAM:"
  echo "$resultado_pam"
fi

echo "✅ Auditoria finalizada"
exit 0