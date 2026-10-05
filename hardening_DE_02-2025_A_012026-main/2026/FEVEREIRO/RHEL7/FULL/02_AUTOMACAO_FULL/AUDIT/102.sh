#!/usr/bin/env bash

echo -e "\n[102] Wireless/Bluetooth desabilitados"

if lsmod 2>/dev/null | grep -Eq '^(bluetooth|iwlwifi)\b'; then
  echo "FAIL"
else
  echo "PASS"
fi
