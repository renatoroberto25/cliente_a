#!/usr/bin/env bash
echo -e "\n[16] NX/XD"
if grep -qi ' nx ' /proc/cpuinfo; then
  echo "PASS"
else
  echo "FAIL"
fi
