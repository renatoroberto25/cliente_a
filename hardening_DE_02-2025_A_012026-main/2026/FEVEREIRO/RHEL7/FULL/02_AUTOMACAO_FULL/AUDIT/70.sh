#!/usr/bin/env bash
echo -e "\n[70] Samba ausente"
rpm -q samba &>/dev/null && echo "FAIL" || echo "PASS"
