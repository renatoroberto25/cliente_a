#!/usr/bin/env bash
echo -e "\n[9] usb-storage"

if ! modinfo usb-storage &>/dev/null; then
  echo "PASS"
elif modprobe --showconfig | grep -Pq '^\s*(install|blacklist)\s+usb-storage\b' \
     && ! lsmod | awk '{print $1}' | grep -qx usb_storage; then
  echo "PASS"
else
  echo "FAIL"
fi
