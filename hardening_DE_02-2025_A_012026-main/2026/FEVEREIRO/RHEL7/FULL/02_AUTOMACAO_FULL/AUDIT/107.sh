#!/usr/bin/env bash

echo -e "\n[107] Regras de firewall persistentes (RHEL 7)"

if [ -s /etc/sysconfig/iptables ]; then
  echo "PASS"
else
  echo "FAIL"
fi
