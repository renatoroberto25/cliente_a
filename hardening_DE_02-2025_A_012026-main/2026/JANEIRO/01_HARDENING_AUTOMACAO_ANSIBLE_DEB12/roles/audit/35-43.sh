#!/usr/bin/env bash

echo -e "\n[35] Montagem segura de partições e mídia removível"
(grep -E 'nodev|nosuid|noexec' /etc/fstab >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[36] Opções de montagem seguras em partições críticas"
(findmnt -n /var | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[37] Opções de montagem seguras em /tmp"
(findmnt -n /tmp | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[38] Opções de montagem seguras em /dev/shm"
(findmnt -n /dev/shm | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[39] Opções de montagem seguras em /var/tmp"
(findmnt -n /var/tmp | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[40] Opções de montagem seguras em /var/log"
(findmnt -n /var/log | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[41] Opções de montagem seguras em /var/log/audit"
(findmnt -n /var/log/audit | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[42] Opções de montagem seguras em /home"
(findmnt -n /home | grep -qw nodev && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[43] Opções de montagem seguras em mídias removíveis"
(grep -E 'nodev|nosuid|noexec' /etc/fstab | grep -E '/media|/run/media' >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")
