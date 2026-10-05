#!/usr/bin/env bash
echo -e "\n[5] hfsplus"

if ! modinfo hfsplus &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+hfsplus\b' \
     && ! lsmod | awk '{print $1}' | grep -qx hfsplus; then
  echo "PASS"
else
  echo "FAIL"
fi
