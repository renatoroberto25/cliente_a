#!/usr/bin/env bash
echo -e "\n[45] Sticky bit em /tmp"

if stat -c "%A" /tmp 2>/dev/null | grep -q 't'; then
  echo "PASS"
else
  echo "FAIL"
fi
