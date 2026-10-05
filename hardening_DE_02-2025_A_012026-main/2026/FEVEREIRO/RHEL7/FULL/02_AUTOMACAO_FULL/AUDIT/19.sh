#!/usr/bin/env bash
echo -e "\n[19] perf_event_paranoid"
if sysctl -n kernel.perf_event_paranoid 2>/dev/null | grep -Eq '^[2-3]$'; then
  echo "PASS"
else
  echo "FAIL"
fi
