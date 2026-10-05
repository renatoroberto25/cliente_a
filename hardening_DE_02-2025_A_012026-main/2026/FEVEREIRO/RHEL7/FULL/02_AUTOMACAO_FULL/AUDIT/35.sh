#!/usr/bin/env bash
echo -e "\n[35] /mnt e /media no fstab (nodev,nosuid,noexec)"

grep -E '^[[:space:]]*[^#]' /etc/fstab 2>/dev/null \
| grep -E '([[:space:]]|^)(/mnt|/media)([[:space:]]|$)' \
| grep -qw nodev \
&& grep -E '^[[:space:]]*[^#]' /etc/fstab | grep -E '(/mnt|/media)' | grep -qw nosuid \
&& grep -E '^[[:space:]]*[^#]' /etc/fstab | grep -E '(/mnt|/media)' | grep -qw noexec \
&& echo "PASS" || echo "FAIL"
