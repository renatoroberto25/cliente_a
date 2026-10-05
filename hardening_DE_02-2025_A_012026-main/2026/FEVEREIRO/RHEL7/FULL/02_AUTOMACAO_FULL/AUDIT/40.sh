#!/usr/bin/env bash
echo -e "\n[40] /var/log (nodev,nosuid,noexec)"

findmnt -n /var/log -o OPTIONS 2>/dev/null \
| grep -qw nodev \
&& findmnt -n /var/log -o OPTIONS | grep -qw nosuid \
&& findmnt -n /var/log -o OPTIONS | grep -qw noexec \
&& echo "PASS" || echo "FAIL"
