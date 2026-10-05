#!/usr/bin/env bash
# [39–46] Auditoria HITSS - SELinux e serviços relacionados (Servidores baseados em RHEL 7)
set -euo pipefail

echo -e "\n[39] Verifique se o SELinux está instalado"
rpm -q libselinux &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[40] Verifique se o SELinux não está desabilitado no bootloader"
grep -Eiq 'selinux=0|enforcing=0' $(find /boot /boot/efi /etc -type f -name 'grub*.cfg' 2>/dev/null | head -n1) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[41] Verifique se uma política SELinux está configurada"
grep -Eq '^SELINUXTYPE=' /etc/selinux/config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[42] Verifique se o modo SELinux é enforcing ou permissive"
getenforce | grep -Eq 'Enforcing|Permissive' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[43] Verifique se o modo SELinux é enforcing"
grep -Eq '^SELINUX=enforcing' /etc/selinux/config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[44] Verifique se não existem serviços não confinados"
ps -eZ | grep -q unconfined_service_t && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[45] Verifique se o SETroubleshoot não está instalado"
rpm -q setroubleshoot &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[46] Verifique se o serviço mcstrans não está instalado"
rpm -q mcstrans &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"