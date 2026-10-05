#!/usr/bin/env bash
echo "[52 - 54] Correção de permissões dos arquivos de banner"

for file in /etc/motd /etc/issue /etc/issue.net; do
    if [ -e "$file" ]; then
        OWNER=$(stat -c "%U" "$file")
        GROUP=$(stat -c "%G" "$file")
        PERM=$(stat -c "%a" "$file")

        if [ "$OWNER" != "root" ] || [ "$GROUP" != "root" ] || [[ ! "$PERM" =~ ^64[0-4]$ ]]; then
            echo "⚠️ Corrigindo permissões de $file..."
            chown root:root "$file"
            chmod 644 "$file"
            echo "✅ Permissões corrigidas: $(stat -c "%a %U %G" "$file")"
        else
            echo "✅ $file já está com permissões corretas"
        fi
    else
        echo "⚠️ $file não existe, nada a corrigir"
    fi
done