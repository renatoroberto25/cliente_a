#!/usr/bin/env bash

echo -e "\n[97] Respostas ICMP inválidas ignoradas"

if [ "$(sysctl -n net.ipv4.icmp_ignore_bogus_error_responses 2>/dev/null)" = "1" ]; then
  echo "PASS"
else
  echo "FAIL"
fi
