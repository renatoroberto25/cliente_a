#!/usr/bin/env bash
echo -e "\n[11] sctp"

if ! modinfo sctp &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+sctp\b' \
     && ! lsmod | awk '{print $1}' | grep -qx sctp; then
  echo "PASS"
else
  echo "FAIL"
fi
