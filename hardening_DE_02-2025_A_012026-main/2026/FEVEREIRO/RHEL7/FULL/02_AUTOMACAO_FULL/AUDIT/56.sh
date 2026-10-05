#!/usr/bin/env bash

echo -e "\n[56] Prelink removido"
if rpm -q prelink &>/dev/null; then
  echo "FAIL"
else
  echo "PASS"
fi
