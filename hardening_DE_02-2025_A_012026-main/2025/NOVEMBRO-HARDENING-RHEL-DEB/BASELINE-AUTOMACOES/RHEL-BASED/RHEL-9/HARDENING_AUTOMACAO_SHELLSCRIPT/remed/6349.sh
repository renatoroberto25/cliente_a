#!/usr/bin/env bash

echo "274 Ensure audit tools owner is configured"
audit_tools_nao_root=$(stat -Lc "%n %U" /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules | awk '$2 != "root" {print}')

if [ -n "$audit_tools_nao_root" ]; then
  echo "Os seguintes executáveis não pertencem ao usuário root:"
  echo "$audit_tools_nao_root"
  chown root /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules
  echo "⚠️ Executado chown root"
else
  echo "[✅ SUCESSO]: - Todas as ferramentas de audit em /sbin pertencem ao usuário root."
fi

echo "275 Ensure audit tools group owner is configured"
audit_tools_nao_root_group=$(stat -Lc "%n %G" /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules | awk '$2 != "root" {print}')

if [ -n "$audit_tools_nao_root_group" ]; then
  echo "Os seguintes executáveis não pertencem ao grupo root:"
  echo "$audit_tools_nao_root_group"
  echo "⚠️ Executado chgrp root"
  chgrp root /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules
else
  echo "[✅ SUCESSO]: - Todas as ferramentas de audit em /sbin pertencem ao grupo root."
fi