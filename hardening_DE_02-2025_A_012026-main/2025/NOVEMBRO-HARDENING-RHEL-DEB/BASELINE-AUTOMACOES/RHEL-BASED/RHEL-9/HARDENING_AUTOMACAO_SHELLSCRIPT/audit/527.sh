#!/usr/bin/env bash

echo " [171] Verificar se o acesso ao comando su está restrito via pam_wheel"

if grep -Piq '^\s*auth\s+(required|requisite)\s+pam_wheel\.so\s+.*(use_uid\b).*group=' /etc/pam.d/su; then
  echo "✅ [APROVADO] Configuração do pam_wheel.so encontrada e restrição ao grupo aplicada"
else
  echo "⚠️ [REPROVADO] Acesso ao comando su não está devidamente restrito via pam_wheel"
fi

echo -e "\n✅ Auditoria finalizada"
exit 0