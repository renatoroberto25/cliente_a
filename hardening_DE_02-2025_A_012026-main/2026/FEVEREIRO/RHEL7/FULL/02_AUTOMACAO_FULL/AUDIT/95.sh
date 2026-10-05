#!/usr/bin/env bash

echo -e "\n[95] Reverse path filtering habilitado"

if [[ "$(sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null)" =~ ^[12]$ ]] && \
   [[ "$(sysctl -n net.ipv4.conf.default.rp_filter 2>/dev/null)" =~ ^[12]$ ]]; then
  echo "PASS"
else
  echo "FAIL"
fi
