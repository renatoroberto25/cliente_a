#!/usr/bin/env bash
echo -e "\n[65] LDAP server ausente"
rpm -q openldap-servers &>/dev/null && echo "FAIL" || echo "PASS"
