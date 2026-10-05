#!/usr/bin/env bash
echo -e "\n[12] rds"

if ! modinfo rds &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+rds\b' \
     && ! lsmod | awk '{print $1}' | grep -qx rds; then
  echo "PASS"
else
  echo "FAIL"
fi
