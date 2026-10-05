#!/usr/bin/env bash
echo -e "\n[52] Verifique se permissões de /etc/motd estão corretas"
if [ -e /etc/motd ]; then
    if stat -Lc "%a %U %G" /etc/motd | grep -Eq "^64[0-4] root root$"; then
        echo "✅ APROVADO"
    else
        echo "⚠️ REPROVADO"
        stat -Lc "Permissões atuais: %a %U %G" /etc/motd
    fi
else
    echo "⚠️ REPROVADO - /etc/motd não existe"
fi

echo -e "\n[53] Verifique se permissões de /etc/issue estão corretas"
if [ -e /etc/issue ]; then
    if stat -Lc "%a %U %G" /etc/issue | grep -Eq "^64[0-4] root root$"; then
        echo "✅ APROVADO"
    else
        echo "⚠️ REPROVADO"
        stat -Lc "Permissões atuais: %a %U %G" /etc/issue
    fi
else
    echo "⚠️ REPROVADO - /etc/issue não existe"
fi

echo -e "\n[54] Verifique se permissões de /etc/issue.net estão corretas"
if [ -e /etc/issue.net ]; then
    if stat -Lc "%a %U %G" /etc/issue.net | grep -Eq "^64[0-4] root root$"; then
        echo "✅ APROVADO"
    else
        echo "⚠️ REPROVADO"
        stat -Lc "Permissões atuais: %a %U %G" /etc/issue.net
    fi
else
    echo "⚠️ REPROVADO - /etc/issue.net não existe"
fi