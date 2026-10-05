#!/usr/bin/env bash

echo -e "\n[44] Sticky bit em diretórios world-writable"
(find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | grep . && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[45] Sticky bit em /tmp"
(stat -c "%A" /tmp | grep -q 't' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[46] Sticky bit em /var/tmp"
(stat -c "%A" /var/tmp | grep -q 't' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[47] Sticky bit em /dev/shm"
(stat -c "%A" /dev/shm | grep -q 't' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[48] Autofs desabilitado"
(systemctl is-enabled autofs &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")
