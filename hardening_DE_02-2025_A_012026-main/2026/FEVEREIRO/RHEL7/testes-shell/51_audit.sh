#!/usr/bin/env bash
echo -e "\n[51] Single user mode com autenticação"
if systemctl show emergency.service -p ExecStart 2>/dev/null | grep -vq 'sulogin'; then
  echo "FAIL"
else
  echo "PASS"
fi

