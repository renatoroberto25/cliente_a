#!/usr/bin/env bash
echo -e "\n[39] /var/tmp (nodev,nosuid,noexec)"

findmnt -n /var/tmp -o OPTIONS 2>/dev/null \
| grep -qw nodev \
&& findmnt -n /var/tmp -o OPTIONS | grep -qw nosuid \
&& findmnt -n /var/tmp -o OPTIONS | grep -qw noexec \
&& echo "PASS" || echo "FAIL"
