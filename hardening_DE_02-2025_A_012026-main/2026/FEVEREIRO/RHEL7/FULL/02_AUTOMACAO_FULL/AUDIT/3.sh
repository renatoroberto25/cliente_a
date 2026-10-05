#!/usr/bin/env bash
echo -e "\n[3] udf"

if ! modinfo udf &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+udf\b' \
     && ! lsmod | awk '{print $1}' | grep -qx udf; then
  echo "PASS"
else
  echo "FAIL"
fi
