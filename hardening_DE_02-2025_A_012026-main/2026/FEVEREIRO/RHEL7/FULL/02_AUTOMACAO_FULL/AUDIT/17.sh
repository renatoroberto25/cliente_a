#!/usr/bin/env bash
echo -e "\n[17] ASLR"
if sysctl -n kernel.randomize_va_space 2>/dev/null | grep -qx '2'; then
  echo "PASS"
else
  echo "FAIL"
fi
