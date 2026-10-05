#!/usr/bin/env bash
echo -e "\n[50] Permissões seguras no arquivo do bootloader"
if stat -Lc '%a %U %G' /boot/grub2/grub.cfg 2>/dev/null | grep -Eq '^(400|600) root root$'; then
  echo "PASS"
else
  echo "FAIL"
fi
