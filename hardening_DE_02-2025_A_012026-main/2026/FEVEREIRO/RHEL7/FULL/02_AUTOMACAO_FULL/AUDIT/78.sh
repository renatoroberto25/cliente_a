#!/usr/bin/env bash
echo -e "\n[78] rsync daemon controlado"
systemctl is-enabled --quiet rsyncd 2>/dev/null && echo "FAIL" || echo "PASS"
