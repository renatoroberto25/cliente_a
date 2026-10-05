#!/usr/bin/env bash
echo -e "\n[67] FTP server ausente"
rpm -q vsftpd &>/dev/null && echo "FAIL" || echo "PASS"
