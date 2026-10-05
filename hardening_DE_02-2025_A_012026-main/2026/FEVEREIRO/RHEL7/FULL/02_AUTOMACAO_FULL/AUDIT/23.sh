#!/usr/bin/env bash
echo -e "\n[23] protected_hardlinks"
if sysctl -n fs.protected_hardlinks 2>/dev/null | grep -qx '1'; then
  echo "PASS"
else
  echo "FAIL"
fi
