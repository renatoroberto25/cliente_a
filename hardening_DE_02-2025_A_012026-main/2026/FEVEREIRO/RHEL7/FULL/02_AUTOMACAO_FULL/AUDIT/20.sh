#!/usr/bin/env bash
echo -e "\n[20] dmesg_restrict"
if sysctl -n kernel.dmesg_restrict 2>/dev/null | grep -qx '1'; then
  echo "PASS"
else
  echo "FAIL"
fi
