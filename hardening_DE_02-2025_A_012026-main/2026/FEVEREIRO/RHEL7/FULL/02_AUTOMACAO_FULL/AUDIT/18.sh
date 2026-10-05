#!/usr/bin/env bash
echo -e "\n[18] IOMMU"
if grep -qiE 'DMAR|IOMMU' /proc/cpuinfo; then
  if grep -q 'iommu=on' /proc/cmdline; then
    echo "PASS"
  else
    echo "FAIL"
  fi
else
  echo "PASS"
fi
