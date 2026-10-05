#!/usr/bin/env bash
echo -e "\n[6] jffs2"

if ! modinfo jffs2 &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+jffs2\b' \
     && ! lsmod | awk '{print $1}' | grep -qx jffs2; then
  echo "PASS"
else
  echo "FAIL"
fi
