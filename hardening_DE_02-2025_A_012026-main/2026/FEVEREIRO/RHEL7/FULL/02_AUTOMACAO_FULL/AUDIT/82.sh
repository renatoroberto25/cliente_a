#!/usr/bin/env bash
echo -e "\n[82] Cliente telnet ausente"
rpm -q telnet &>/dev/null && echo "FAIL" || echo "PASS"
