#!/usr/bin/env bash
echo -e "\n[36] /var (nodev,nosuid,noexec)"

findmnt -n /var -o OPTIONS 2>/dev/null \
| grep -qw nodev \
&& findmnt -n /var -o OPTIONS | grep -qw nosuid \
&& findmnt -n /var -o OPTIONS | grep -qw noexec \
&& echo "PASS" || echo "FAIL"
