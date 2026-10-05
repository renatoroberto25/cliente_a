#!/usr/bin/env bash

echo -e "\n[104] Apenas uma solução de firewall ativa (iptables-only)"

if systemctl is-active --quiet firewalld 2>/dev/null; then
  echo "FAIL"
else
  echo "PASS"
fi
