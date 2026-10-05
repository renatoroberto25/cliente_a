#!/usr/bin/env bash
echo "208 Ensure root user umask is configured"

FILES=("/root/.bash_profile" "/root/.bashrc")

# Verificar umask em cada arquivo
for FILE in "${FILES[@]}"; do
    if grep -Psi -- '^\h*umask\h+(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b|[0-7][0-7][0-6]\b)|(u=[rwx]{1,3},)?(((g=[rx]?[rx]?w[rx]?[rx]?\b)(,o=[rwx]{1,3})?)|((g=[wrx]{1,3},)?o=[wrx]{1,3}\b)))' "$FILE" > /dev/null 2>&1; then
echo "⚠️ [REPROVADO]: Umask muito permissivo encontrado em $FILE"
    else
echo "✅ [APROVADO]: Nenhum umask muito permissivo em $FILE"
    fi
done