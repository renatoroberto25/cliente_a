#!/usr/bin/env bash
echo -e "\n[1] cramfs"

if ! modinfo cramfs &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+cramfs\b' \
     && ! lsmod | awk '{print $1}' | grep -qx cramfs; then
  echo "PASS"
else
  echo "FAIL"
fi
