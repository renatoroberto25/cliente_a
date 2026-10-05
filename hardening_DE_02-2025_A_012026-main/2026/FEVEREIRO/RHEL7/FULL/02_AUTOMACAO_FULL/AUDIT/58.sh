#!/usr/bin/env bash
echo -e "\n[58] Sincronização de tempo em uso"
if systemctl is-active --quiet chronyd 2>/dev/null || \
   systemctl is-active --quiet ntpd 2>/dev/null || \
   systemctl is-active --quiet systemd-timesyncd 2>/dev/null; then
  echo "PASS"
else
  echo "FAIL"
fi
