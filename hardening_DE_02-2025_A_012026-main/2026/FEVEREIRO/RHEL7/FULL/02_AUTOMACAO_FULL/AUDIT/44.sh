#!/usr/bin/env bash
echo -e "\n[44] Sticky bit em diretórios world-writable"

if find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | grep -q .; then
  echo "FAIL"
else
  echo "PASS"
fi
