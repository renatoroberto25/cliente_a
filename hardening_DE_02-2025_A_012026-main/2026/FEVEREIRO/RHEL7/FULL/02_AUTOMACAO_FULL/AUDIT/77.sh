#!/usr/bin/env bash
echo -e "\n[77] rpcbind controlado"
systemctl is-enabled --quiet rpcbind 2>/dev/null && echo "FAIL" || echo "PASS"
