#!/usr/bin/env bash
# [32-34] Audit HITSS - Bootloader e modo single-user (Servidores baseados em RHEL 7)
set -euo pipefail

echo -e "\n[32] Verifique se o bootloader possui senha configurada"
l_grub_password_file="$(find /boot -type f -name 'user.cfg' ! -empty 2>/dev/null)"
[ -f "$l_grub_password_file" ] && grep -Eq '^\s*GRUB2_PASSWORD=grub\.pbkdf2\.sha512' "$l_grub_password_file" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[33] Verifique se as permissões do arquivo de configuração do bootloader estão corretas"
l_grub_cfg="/boot/grub2/grub.cfg"
if [ -f "$l_grub_cfg" ] && stat -c "%a %U %G" "$l_grub_cfg" | grep -qE '^400 root root$'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

echo -e "\n[34] Verifique se o modo single-user exige autenticação"
if grep -q "sulogin" /usr/lib/systemd/system/rescue.service /usr/lib/systemd/system/emergency.service 2>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi