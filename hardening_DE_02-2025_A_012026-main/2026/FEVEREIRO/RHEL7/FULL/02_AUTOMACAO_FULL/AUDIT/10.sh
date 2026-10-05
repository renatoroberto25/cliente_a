#!/usr/bin/env bash
echo -e "\n[10] dccp"

if ! modinfo dccp &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+dccp\b' \
     && ! lsmod | awk '{print $1}' | grep -qx dccp; then
  echo "PASS"
else
  echo "FAIL"
fi
