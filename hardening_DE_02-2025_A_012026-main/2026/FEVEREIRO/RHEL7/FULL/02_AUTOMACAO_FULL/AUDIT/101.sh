#!/usr/bin/env bash

echo -e "\n[101] ICMP timestamp-reply drop"

if iptables -S INPUT 2>/dev/null | grep -q -- '-p icmp --icmp-type timestamp-reply -j DROP'; then
  echo "PASS"
else
  echo "FAIL"
fi
