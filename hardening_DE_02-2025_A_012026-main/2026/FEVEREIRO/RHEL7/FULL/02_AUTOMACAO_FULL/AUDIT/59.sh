#!/usr/bin/env bash
echo -e "\n[59] Chrony configurado"
if rpm -q chrony &>/dev/null; then
  if systemctl is-active --quiet chronyd 2>/dev/null && \
     grep -Eq '^\s*server\s+' /etc/chrony.conf 2>/dev/null; then
    echo "PASS"
  else
    echo "FAIL"
  fi
else
  echo "PASS"
fi
