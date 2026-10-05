#!/usr/bin/env bash

echo -e "\n[49] Senha de bootloader configurada"
(grep -q 'password_pbkdf2' /boot/grub2/grub.cfg 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[50] Permissões seguras no arquivo do bootloader"
(stat -Lc '%a %U %G' /boot/grub2/grub.cfg 2>/dev/null | grep -Eq '^(400|600) root root$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[51] Single user mode com autenticação"
(grep -q '^ExecStart=-/bin/sh' /usr/lib/systemd/system/emergency.service && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

#MUDAR NO TENABLE AUDIT