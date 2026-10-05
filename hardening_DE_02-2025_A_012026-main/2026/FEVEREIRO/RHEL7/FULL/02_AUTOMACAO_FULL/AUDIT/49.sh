#!/usr/bin/env bash
echo -e "\n[49] Senha de bootloader configurada"
if grep -q 'password_pbkdf2' /boot/grub2/grub.cfg 2>/dev/null; then
  echo "PASS"
else
  echo "FAIL"
fi
