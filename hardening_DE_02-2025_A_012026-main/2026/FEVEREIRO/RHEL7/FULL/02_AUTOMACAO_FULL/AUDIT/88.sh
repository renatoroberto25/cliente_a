#!/usr/bin/env bash
echo -e "\n[88] Patches de segurança aplicados"

if yum updateinfo list security all 2>/dev/null | grep -qE 'RHSA'; then
  echo "FAIL"
else
  echo "PASS"
fi
