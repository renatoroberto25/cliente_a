#!/usr/bin/env bash
echo -e "\n[37] /tmp (nodev,nosuid,noexec)"

findmnt -n /tmp -o OPTIONS 2>/dev/null \
| grep -qw nodev \
&& findmnt -n /tmp -o OPTIONS | grep -qw nosuid \
&& findmnt -n /tmp -o OPTIONS | grep -qw noexec \
&& echo "PASS" || echo "FAIL"
