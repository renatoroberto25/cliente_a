#!/usr/bin/env bash
echo -e "\n[74] Telnet server ausente"
rpm -q telnet-server &>/dev/null && echo "FAIL" || echo "PASS"
