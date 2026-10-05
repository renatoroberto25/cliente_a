#!/usr/bin/env bash

echo -e "\n[52] MAC (SELinux/AppArmor) ativo"
if getenforce 2>/dev/null | grep -Eq 'Enforcing|Permissive'; then
  echo "PASS"
else
  echo "FAIL"
fi
