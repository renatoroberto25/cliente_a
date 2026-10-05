#!/usr/bin/env bash

echo -e "\n[179] Verificar se o módulo pam_unix.so está habilitado"

modulo="unix"

if grep -Pq -- "\bpam_${modulo}\.so\b" /etc/pam.d/{password,system}-auth 2>/dev/null; then
    echo "✅ [APROVADO]: pam_${modulo}.so encontrado nos arquivos PAM"
else
    echo "⚠️ [REPROVADO]: pam_${modulo}.so NÃO encontrado nos arquivos PAM"
fi