#!/usr/bin/env bash
echo -e "\n[24] suid_dumpable"
if sysctl -n fs.suid_dumpable 2>/dev/null | grep -qx '0'; then
  echo "PASS"
else
  echo "FAIL"
fi
