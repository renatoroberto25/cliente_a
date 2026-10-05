#!/usr/bin/env bash
echo -e "\n[66] DNS server ausente"
rpm -q bind &>/dev/null && echo "FAIL" || echo "PASS"
