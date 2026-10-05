#!/usr/bin/env bash
echo -e "\n[7] freevxfs"

if ! modinfo freevxfs &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+freevxfs\b' \
     && ! lsmod | awk '{print $1}' | grep -qx freevxfs; then
  echo "PASS"
else
  echo "FAIL"
fi
