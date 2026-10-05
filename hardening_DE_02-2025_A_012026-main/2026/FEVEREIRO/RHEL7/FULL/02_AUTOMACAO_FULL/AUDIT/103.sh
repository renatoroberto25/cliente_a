#!/usr/bin/env bash

echo -e "\n[103] Firewall com política default deny"

if iptables -L INPUT -n 2>/dev/null | grep -q 'policy DROP' && \
   iptables -L FORWARD -n 2>/dev/null | grep -q 'policy DROP' && \
   iptables -L OUTPUT -n 2>/dev/null | grep -q 'policy DROP'; then
  echo "PASS"
else
  echo "FAIL"
fi
