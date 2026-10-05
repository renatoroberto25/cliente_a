#!/usr/bin/env bash

echo -e "\n[96] ICMP broadcast ignorado"

if [ "$(sysctl -n net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null)" = "1" ]; then
  echo "PASS"
else
  echo "FAIL"
fi
