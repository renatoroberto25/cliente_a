#!/usr/bin/env bash
echo -e "\n[79] Cliente NIS ausente"
rpm -q ypbind &>/dev/null && echo "FAIL" || echo "PASS"
