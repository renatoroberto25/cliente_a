#!/usr/bin/env bash

echo -e "\n[90] Cron/at seguros e restritos"

if [ -f /etc/cron.allow ] && \
   stat -Lc '%a %U %G' /etc/cron.allow 2>/dev/null | grep -Eq '^640 root (root|crontab)$'; then
  echo "PASS"
else
  echo "FAIL"
fi
