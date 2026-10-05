#!/usr/bin/env bash
echo -e "\n[25] Partição dedicada para /tmp"
(findmnt -kn /tmp >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[26] Partição dedicada para /dev/shm"
(findmnt -kn /dev/shm >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[27] Partição dedicada para /var"
(findmnt -kn /var >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[28] Partição dedicada para /var/tmp"
(findmnt -kn /var/tmp >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[29] Partição dedicada para /var/log"
(findmnt -kn /var/log >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[30] Partição dedicada para /var/log/audit"
(findmnt -kn /var/log/audit >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[31] Partição dedicada para /home"
(findmnt -kn /home >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[32] Partição dedicada para /historico"
(findmnt -kn /historico >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[33] Partição dedicada para /crash"
(findmnt -kn /crash >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[34] Partição dedicada para /UNIX"
(findmnt -kn /UNIX >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")
