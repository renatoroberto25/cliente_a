#!/usr/bin/env bash
echo -e "\n[8] overlay"

if ! modinfo overlay &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+overlay\b' \
     && ! lsmod | awk '{print $1}' | grep -qx overlay; then
  echo "PASS"
else
  echo "FAIL"
fi
