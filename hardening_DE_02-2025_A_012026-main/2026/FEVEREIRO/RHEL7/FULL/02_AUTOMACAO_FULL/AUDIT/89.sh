#!/usr/bin/env bash

echo -e "\n[89] Apenas um daemon de time sync"

if [ "$(systemctl is-active chronyd ntpd 2>/dev/null | grep -c '^active$')" -eq 1 ]; then
  echo "PASS"
else
  echo "FAIL"
fi
