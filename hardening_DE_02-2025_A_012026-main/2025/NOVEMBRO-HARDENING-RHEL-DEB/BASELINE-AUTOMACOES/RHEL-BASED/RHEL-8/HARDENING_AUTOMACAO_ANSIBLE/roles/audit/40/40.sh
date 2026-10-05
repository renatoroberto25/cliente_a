#!/usr/bin/env bash
echo -e "\n[40] Verifique se o bootloader possui senha configurada"

l_grub_password_file="$(find /boot -type f -name 'user.cfg' ! -empty 2>/dev/null)"
[ -f "$l_grub_password_file" ] && grep -Eq '^\s*GRUB2_PASSWORD=grub\.pbkdf2\.sha512' "$l_grub_password_file" && echo -e "✅ APROVADO \n" || echo -e "⚠️ REPROVADO \n"