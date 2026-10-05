#!/usr/bin/env bash
echo -e "\n[42] /home (nodev)"

findmnt -n /home -o OPTIONS 2>/dev/null \
| grep -qw nodev \
&& echo "PASS" || echo "FAIL"
