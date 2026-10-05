#!/usr/bin/env bash
echo -e "\n[38] /dev/shm (nodev,nosuid,noexec)"

findmnt -n /dev/shm -o OPTIONS 2>/dev/null \
| grep -qw nodev \
&& findmnt -n /dev/shm -o OPTIONS | grep -qw nosuid \
&& findmnt -n /dev/shm -o OPTIONS | grep -qw noexec \
&& echo "PASS" || echo "FAIL"
