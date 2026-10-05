#!/usr/bin/env bash
echo -e "\n[15] ptrace_scope"
if sysctl -n kernel.yama.ptrace_scope 2>/dev/null | grep -Eq '^[1-3]$'; then
  echo "PASS"
elif ! sysctl -n kernel.yama.ptrace_scope &>/dev/null; then
  echo "PASS"
else
  echo "FAIL"
fi
