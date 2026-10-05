#!/usr/bin/env bash
echo -e "\n[62] Avahi ausente"
rpm -q avahi &>/dev/null && echo "FAIL" || echo "PASS"
