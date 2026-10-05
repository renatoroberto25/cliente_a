#!/usr/bin/env bash
echo -e "\n[43] /media e /run/media no fstab (nodev,nosuid,noexec)"

grep -E '^[[:space:]]*[^#]' /etc/fstab 2>/dev/null \
| grep -E '([[:space:]]|^)(/media|/run/media)([[:space:]]|$)' \
| grep -qw nodev \
&& grep -E '^[[:space:]]*[^#]' /etc/fstab | grep -E '(/media|/run/media)' | grep -qw nosuid \
&& grep -E '^[[:space:]]*[^#]' /etc/fstab | grep -E '(/media|/run/media)' | grep -qw noexec \
&& echo "PASS" || echo "FAIL"
