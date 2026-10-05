#!/usr/bin/env bash
echo -e "\n[81] Cliente talk ausente"
rpm -q talk &>/dev/null && echo "FAIL" || echo "PASS"
