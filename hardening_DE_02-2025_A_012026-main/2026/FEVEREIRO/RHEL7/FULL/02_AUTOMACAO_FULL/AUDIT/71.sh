#!/usr/bin/env bash
echo -e "\n[71] Proxy HTTP ausente"
rpm -q squid &>/dev/null && echo "FAIL" || echo "PASS"
