#!/usr/bin/env bash
echo "[45] Restringir acesso ao arquivo de configuração do bootloader"

if [ -f /boot/grub/grub.cfg ]; then
    PERM="$(stat -c "%a" /boot/grub/grub.cfg)"
    OWNER="$(stat -c "%U" /boot/grub/grub.cfg)"
    GROUP="$(stat -c "%G" /boot/grub/grub.cfg)"

    if [ "$PERM" = "400" ] && [ "$OWNER" = "root" ] && [ "$GROUP" = "root" ]; then
        echo "✅ Já está conforme (root:root 400)"
    else
        echo "⚠️ Corrigindo permissões de /boot/grub/grub.cfg..."
        chown root:root /boot/grub/grub.cfg
        chmod 400 /boot/grub/grub.cfg
        echo "✅ Permissões corrigidas: $(stat -c "%U %G %a" /boot/grub/grub.cfg)"
    fi
else
    echo "❗ Arquivo /boot/grub/grub.cfg não encontrado"
fi