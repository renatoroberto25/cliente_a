#!/usr/bin/env bash
echo -e "\n[87] Assinaturas de pacotes habilitadas"

if grep -RiqE '^\s*gpgcheck\s*=\s*0' /etc/yum.conf /etc/yum.repos.d 2>/dev/null; then
  echo "FAIL"
elif grep -RiqE '^\s*gpgcheck\s*=\s*1' /etc/yum.conf /etc/yum.repos.d 2>/dev/null; then
  echo "PASS"
else
  echo "FAIL"
fi
