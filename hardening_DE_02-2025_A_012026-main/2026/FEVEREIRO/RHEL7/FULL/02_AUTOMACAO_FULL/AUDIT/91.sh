#!/usr/bin/env bash

echo -e "\n[91] IP forwarding desabilitado"

if [ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" = "0" ] && \
   [ "$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null)" = "0" ]; then
  echo "PASS"
else
  echo "FAIL"
fi
