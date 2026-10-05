#!/usr/bin/env bash
echo -e "\n[83] Cliente LDAP ausente"
rpm -q openldap-clients &>/dev/null && echo "FAIL" || echo "PASS"
