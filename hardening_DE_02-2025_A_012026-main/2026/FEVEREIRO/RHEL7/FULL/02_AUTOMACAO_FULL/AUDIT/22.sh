#!/usr/bin/env bash
echo -e "\n[22] protected_symlinks"
if sysctl -n fs.protected_symlinks 2>/dev/null | grep -qx '1'; then
  echo "PASS"
else
  echo "FAIL"
fi
