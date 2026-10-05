#!/usr/bin/env bash
set -euo pipefail
echo "[201 - 202] Configurar ambiente padrão do usuário"

# 201 Ensure default user shell timeout is configured
echo -e "\n[201] Verificar TMOUT <= 900, readonly e exportado"
FILES=("/etc/profile" "/etc/bashrc" /etc/profile.d/*.sh)
if grep -Pqs '^[[:space:]]*TMOUT=(900|[1-8][0-9]{2}|[1-9][0-9]?)[[:space:]]*$' "${FILES[@]}" \
   && grep -Pqs '^[[:space:]]*readonly[[:space:]]+TMOUT\b' "${FILES[@]}" \
   && grep -Pqs '^[[:space:]]*export[[:space:]]+TMOUT\b' "${FILES[@]}"; then
    echo "✅ TMOUT configurado corretamente"
else
    echo "⚠️ TMOUT ausente, inválido ou configurado incorretamente"
fi

# 202 Ensure default user umask is configured
echo -e "\n[202] Verificar umask padrão 027"
FILES=("/etc/profile" "/etc/bashrc" "/etc/login.defs" /etc/profile.d/*.sh)
if grep -Pqs '^[[:space:]]*umask[[:space:]]+0?27\b' "${FILES[@]}"; then
    echo "✅ umask padrão configurado como 027"
else
    echo "⚠️ umask padrão não encontrado ou incorreto"
fi