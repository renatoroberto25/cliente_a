#!/usr/bin/env bash
echo -e "\n[21] user namespaces"
if sysctl -n user.max_user_namespaces 2>/dev/null | grep -qx '0'; then
  echo "PASS"
elif ! sysctl -n user.max_user_namespaces &>/dev/null; then
  echo "PASS"
else
  echo "FAIL"
fi
