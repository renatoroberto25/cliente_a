#!/usr/bin/env bash

echo -e "\n[99] IPv6 desabilitado (template)"

if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)" = "1" ] && \
   [ "$(sysctl -n net.ipv6.conf.default.disable_ipv6 2>/dev/null)" = "1" ]; then
  echo "PASS"
else
  echo "FAIL"
fi
