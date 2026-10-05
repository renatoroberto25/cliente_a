#!/usr/bin/env bash

echo -e "\n[100] ICMP timestamp-request drop"

if iptables -S INPUT 2>/dev/null | grep -q -- '-p icmp --icmp-type timestamp-request -j DROP'; then
  echo "PASS"
else
  echo "FAIL"
fi
