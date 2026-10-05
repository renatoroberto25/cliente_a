#!/usr/bin/env bash
echo -e "\n[47] Sticky bit em /dev/shm"

if stat -c "%A" /dev/shm 2>/dev/null | grep -q 't'; then
  echo "PASS"
else
  echo "FAIL"
fi
