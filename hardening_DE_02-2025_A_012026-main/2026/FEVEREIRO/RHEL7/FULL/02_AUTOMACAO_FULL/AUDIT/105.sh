#!/usr/bin/env bash

echo -e "\n[105] Regras básicas de firewall"

if iptables -S INPUT 2>/dev/null | grep -q '^-A INPUT -i lo -j ACCEPT' && \
   iptables -S INPUT 2>/dev/null | grep -q 'ESTABLISHED,RELATED'; then
  echo "PASS"
else
  echo "FAIL"
fi
