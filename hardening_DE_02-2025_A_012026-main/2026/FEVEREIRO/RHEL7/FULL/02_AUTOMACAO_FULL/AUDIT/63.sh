#!/usr/bin/env bash
echo -e "\n[63] CUPS ausente"
rpm -q cups &>/dev/null && echo "FAIL" || echo "PASS"
