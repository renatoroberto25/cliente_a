#!/usr/bin/env bash
echo -e "\n[76] NFS server controlado"
systemctl is-enabled --quiet nfs-server 2>/dev/null && echo "FAIL" || echo "PASS"
