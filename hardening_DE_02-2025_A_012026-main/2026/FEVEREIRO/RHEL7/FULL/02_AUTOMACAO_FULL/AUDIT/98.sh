#!/usr/bin/env bash

echo -e "\n[98] TCP SYN cookies habilitados"

if [ "$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null)" = "1" ]; then
  echo "PASS"
else
  echo "FAIL"
fi
