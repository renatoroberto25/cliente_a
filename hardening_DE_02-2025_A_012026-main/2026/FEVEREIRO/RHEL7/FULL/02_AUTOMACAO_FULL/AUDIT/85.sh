#!/usr/bin/env bash
echo -e "\n[85] TFTP server removido"
rpm -q tftp-server &>/dev/null && echo "FAIL" || echo "PASS"
