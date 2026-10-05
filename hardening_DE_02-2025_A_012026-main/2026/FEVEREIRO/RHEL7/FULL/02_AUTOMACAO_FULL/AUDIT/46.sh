#!/usr/bin/env bash
echo -e "\n[46] Sticky bit em /var/tmp"

if stat -c "%A" /var/tmp 2>/dev/null | grep -q 't'; then
  echo "PASS"
else
  echo "FAIL"
fi
