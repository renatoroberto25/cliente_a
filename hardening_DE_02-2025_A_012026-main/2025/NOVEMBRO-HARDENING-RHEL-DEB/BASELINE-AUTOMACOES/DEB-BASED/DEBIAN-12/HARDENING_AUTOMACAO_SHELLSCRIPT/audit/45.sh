#!/usr/bin/env bash
echo -e "\n[45] Verifique se o acesso ao arquivo de configuração do bootloader está restrito"

if [ -f /boot/grub/grub.cfg ]; then
    if stat -c "%a %U %G" /boot/grub/grub.cfg | grep -Eq "^(400|600) root root$"; then
        echo "✅ APROVADO"
    else
        echo "⚠️ REPROVADO"
        # echo "Permissões atuais: $(stat -c "%U %G %a" /boot/grub/grub.cfg)"
    fi
else
    echo "❗ Arquivo /boot/grub/grub.cfg não encontrado"
fi
