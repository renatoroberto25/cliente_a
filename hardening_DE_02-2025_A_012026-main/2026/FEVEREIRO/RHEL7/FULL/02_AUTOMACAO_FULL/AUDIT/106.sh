#!/usr/bin/env bash

echo -e "\n[106] Regras explícitas para portas TCP abertas"

PORTS=$(ss -H -tln 2>/dev/null | awk '{print $4}' | sed -E 's/.*:([0-9]+)$/\1/' | sort -u)
for p in $PORTS; do
  iptables -S INPUT 2>/dev/null | grep -q -- "--dport $p " || { echo "FAIL"; exit 0; }
done
echo "PASS"
