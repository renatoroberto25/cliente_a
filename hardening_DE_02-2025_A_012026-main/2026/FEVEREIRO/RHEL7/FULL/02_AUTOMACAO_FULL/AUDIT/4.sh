#!/usr/bin/env bash
echo -e "\n[4] hfs"

if ! modinfo hfs &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+hfs\b' \
     && ! lsmod | awk '{print $1}' | grep -qx hfs; then
  echo "PASS"
else
  echo "FAIL"
fi
