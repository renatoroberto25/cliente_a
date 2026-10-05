#!/usr/bin/env bash
echo -e "\n[13] tipc"

if ! modinfo tipc &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+tipc\b' \
     && ! lsmod | awk '{print $1}' | grep -qx tipc; then
  echo "PASS"
else
  echo "FAIL"
fi
