#!/usr/bin/env bash
echo -e "\n[84] Serviços não essenciais habilitados"

if systemctl list-unit-files --state=enabled 2>/dev/null | grep -Eq '^(avahi-daemon|cups|telnet|vsftpd|xinetd|tftp)'; then
  echo "FAIL"
else
  echo "PASS"
fi
