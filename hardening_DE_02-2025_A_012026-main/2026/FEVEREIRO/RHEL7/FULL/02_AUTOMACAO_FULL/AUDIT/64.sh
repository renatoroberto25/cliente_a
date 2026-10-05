#!/usr/bin/env bash
echo -e "\n[64] DHCP server ausente"
rpm -q dhcp-server &>/dev/null && echo "FAIL" || echo "PASS"
