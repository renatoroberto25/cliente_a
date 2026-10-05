#!/usr/bin/env bash
echo -e "\n[75] MTA em modo local-only"

if [ ! -f /etc/postfix/main.cf ]; then
  echo "PASS"
elif grep -Eq '^[[:space:]]*inet_interfaces[[:space:]]*=[[:space:]]*(localhost|loopback-only)\b' /etc/postfix/main.cf 2>/dev/null; then
  echo "PASS"
else
  echo "FAIL"
fi
