#!/usr/bin/env bash
echo -e "\n[48] Autofs desabilitado"

if systemctl is-enabled autofs &>/dev/null; then
  echo "FAIL"
else
  echo "PASS"
fi
