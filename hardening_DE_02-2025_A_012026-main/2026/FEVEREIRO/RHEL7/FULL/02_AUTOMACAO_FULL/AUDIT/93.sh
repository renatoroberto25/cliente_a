#!/usr/bin/env bash

echo -e "\n[93] Source-routed packets bloqueados"

if [ "$(sysctl -n net.ipv4.conf.all.accept_source_route 2>/dev/null)" = "0" ] && \
   [ "$(sysctl -n net.ipv4.conf.default.accept_source_route 2>/dev/null)" = "0" ]; then
  echo "PASS"
else
  echo "FAIL"
fi
