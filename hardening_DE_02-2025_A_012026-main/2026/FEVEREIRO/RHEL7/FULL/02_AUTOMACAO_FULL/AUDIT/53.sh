#!/usr/bin/env bash

echo -e "\n[53] Política MAC definida"
if sestatus 2>/dev/null | grep -q 'Loaded policy name'; then
  echo "PASS"
else
  echo "FAIL"
fi
