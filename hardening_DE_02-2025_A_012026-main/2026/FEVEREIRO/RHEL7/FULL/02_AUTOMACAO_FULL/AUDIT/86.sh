#!/usr/bin/env bash
echo -e "\n[86] PolicyKit endurecido"

if grep -REq 'polkit\.Result\.YES|allow' /etc/polkit-1/rules.d/*.rules 2>/dev/null; then
  echo "FAIL"
else
  echo "PASS"
fi
