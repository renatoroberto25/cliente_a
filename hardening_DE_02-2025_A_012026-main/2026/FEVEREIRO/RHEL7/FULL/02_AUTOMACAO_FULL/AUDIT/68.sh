#!/usr/bin/env bash
echo -e "\n[68] HTTP server ausente"
rpm -q httpd &>/dev/null && echo "FAIL" || echo "PASS"
