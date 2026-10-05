#!/usr/bin/env bash

echo -e "\n[57] xinetd removido"
if rpm -q xinetd &>/dev/null; then
  echo "FAIL"
else
  echo "PASS"
fi
