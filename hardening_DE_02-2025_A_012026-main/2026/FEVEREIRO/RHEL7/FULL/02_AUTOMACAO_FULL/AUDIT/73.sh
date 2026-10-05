#!/usr/bin/env bash
echo -e "\n[73] NIS server ausente"
rpm -q ypserv &>/dev/null && echo "FAIL" || echo "PASS"
