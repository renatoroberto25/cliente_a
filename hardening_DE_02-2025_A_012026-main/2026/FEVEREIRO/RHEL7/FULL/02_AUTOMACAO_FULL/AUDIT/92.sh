#!/usr/bin/env bash

echo -e "\n[92] Redirecionamentos de pacotes desabilitados"

if [ "$(sysctl -n net.ipv4.conf.all.send_redirects 2>/dev/null)" = "0" ] && \
   [ "$(sysctl -n net.ipv4.conf.default.send_redirects 2>/dev/null)" = "0" ]; then
  echo "PASS"
else
  echo "FAIL"
fi
