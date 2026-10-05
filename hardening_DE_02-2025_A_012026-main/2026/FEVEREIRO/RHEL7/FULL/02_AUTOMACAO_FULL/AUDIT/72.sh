#!/usr/bin/env bash
echo -e "\n[72] SNMP ausente"
rpm -q net-snmp &>/dev/null && echo "FAIL" || echo "PASS"
