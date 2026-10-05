#!/usr/bin/env bash
#208 Ensure root user umask is configured
echo "208 Ensure root user umask is configured"

FILES=("/root/.bash_profile" "/root/.bashrc")
UMASK_VALUE="027"
SUCCESS=true

for FILE in "${FILES[@]}"; do
    if [ -w "$FILE" ]; then
        # Verifica se já está corretamente configurado antes de modificar
        if grep -qE "^\s*umask\s+$UMASK_VALUE\b" "$FILE"; then
            echo "✅ $FILE já está corretamente configurado. Nenhuma alteração necessária."
        else
            echo "✅ Modificando $FILE..."
            sed -i '/umask/d' "$FILE" || { echo "⚠️ Erro ao remover umask antigo de $FILE"; SUCCESS=false; }
            echo "umask $UMASK_VALUE" >> "$FILE" || { echo "⚠️ Erro ao adicionar umask $UMASK_VALUE em $FILE"; SUCCESS=false; }
        fi
    else
        echo "⚠️ Aviso: Não foi possível modificar $FILE (sem permissão de escrita)."
        SUCCESS=false
    fi
done

if $SUCCESS; then
    echo "Aplicando novas configurações..."
    source /root/.bash_profile || echo "⚠️ Aviso: Não foi possível recarregar /root/.bash_profile"
else
    echo "⚠️ Remediação incompleta: Verifique os avisos acima."
fi