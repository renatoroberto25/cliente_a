#!/usr/bin/env bash

echo -e "\n[108] TLS mínimo 1.2 (RHEL 7)"

if [ -d /etc/httpd ]; then
  grep -Rqs 'TLSv1\.2' /etc/httpd 2>/dev/null && echo "PASS" || echo "FAIL"

elif [ -d /etc/nginx ]; then
  grep -Rqs 'TLSv1\.2' /etc/nginx 2>/dev/null && echo "PASS" || echo "FAIL"

else
  echo "PASS"
fi
