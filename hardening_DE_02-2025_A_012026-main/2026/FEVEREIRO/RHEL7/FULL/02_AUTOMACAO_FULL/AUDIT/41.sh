#!/usr/bin/env bash
echo -e "\n[41] /var/log/audit (nodev,nosuid,noexec)"

findmnt -n /var/log/audit -o OPTIONS 2>/dev/null \
| grep -qw nodev \
&& findmnt -n /var/log/audit -o OPTIONS | grep -qw nosuid \
&& findmnt -n /var/log/audit -o OPTIONS | grep -qw noexec \
&& echo "PASS" || echo "FAIL"
