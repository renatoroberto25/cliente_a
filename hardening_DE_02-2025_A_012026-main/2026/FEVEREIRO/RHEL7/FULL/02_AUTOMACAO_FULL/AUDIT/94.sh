#!/usr/bin/env bash

echo -e "\n[94] ICMP redirects bloqueados"

if [ "$(sysctl -n net.ipv4.conf.all.accept_redirects 2>/dev/null)" = "0" ] && \
   [ "$(sysctl -n net.ipv4.conf.default.accept_redirects 2>/dev/null)" = "0" ] && \
   [ "$(sysctl -n net.ipv4.conf.all.secure_redirects 2>/dev/null)" = "0" ] && \
   [ "$(sysctl -n net.ipv4.conf.default.secure_redirects 2>/dev/null)" = "0" ]; then
  echo "PASS"
else
  echo "FAIL"
fi
