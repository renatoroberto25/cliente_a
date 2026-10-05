#!/usr/bin/env bash
echo -e "\n[69] IMAP/POP3 server ausente"
rpm -q dovecot &>/dev/null && echo "FAIL" || echo "PASS"
