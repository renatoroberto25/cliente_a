#!/usr/bin/env bash

echo -e "\n[55] Processos unconfined minimizados"
if (
     getenforce 2>/dev/null | grep -Eq 'Enforcing|Permissive' &&
     ! ps -eZ 2>/dev/null | grep -q 'unconfined_t'
   ) || getenforce 2>/dev/null | grep -q 'Disabled'; then
  echo "PASS"
else
  echo "FAIL"
fi
