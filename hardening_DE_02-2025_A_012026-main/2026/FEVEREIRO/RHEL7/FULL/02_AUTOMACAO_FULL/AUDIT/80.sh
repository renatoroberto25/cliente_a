#!/usr/bin/env bash
echo -e "\n[80] Cliente rsh ausente"
rpm -q rsh &>/dev/null && echo "FAIL" || echo "PASS"
