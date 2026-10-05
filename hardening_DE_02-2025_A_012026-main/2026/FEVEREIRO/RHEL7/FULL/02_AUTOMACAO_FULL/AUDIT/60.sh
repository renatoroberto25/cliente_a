#!/usr/bin/env bash
echo -e "\n[60] NTP clássico removido"
if rpm -q ntp &>/dev/null; then
  echo "FAIL"
else
  echo "PASS"
fi
