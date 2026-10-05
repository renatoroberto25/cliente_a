#!/usr/bin/env bash
echo -e "\n[61] X11 ausente"
rpm -q xorg-x11-server-common &>/dev/null && echo "FAIL" || echo "PASS"
