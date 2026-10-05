#!/usr/bin/env bash
# --- /tmp ---
echo -e "\n[11] Verifique se /tmp é uma partição separada"
(findmnt -kn /tmp | grep -q "/tmp") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[12] Verifique se opção nodev está definida em /tmp"
(findmnt -n -o OPTIONS /tmp | grep -qw nodev) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[13] Verifique se opção nosuid está definida em /tmp"
(findmnt -n -o OPTIONS /tmp | grep -qw nosuid) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[14] Verifique se opção noexec está definida em /tmp"
(findmnt -n -o OPTIONS /tmp | grep -qw noexec) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


# --- /dev/shm ---
echo -e "\n[15] Verifique se /dev/shm é uma partição separada"
(findmnt -kn /dev/shm | grep -q "/dev/shm") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[16] Verifique se opção nodev está definida em /dev/shm"
(findmnt -n -o OPTIONS /dev/shm | grep -qw nodev) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[17] Verifique se opção nosuid está definida em /dev/shm"
(findmnt -n -o OPTIONS /dev/shm | grep -qw nosuid) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[18] Verifique se opção noexec está definida em /dev/shm"
(findmnt -n -o OPTIONS /dev/shm | grep -qw noexec) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


# --- /home ---
echo -e "\n[19] Verifique se /home é uma partição separada"
(findmnt -kn /home | grep -q "/home") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[20] Verifique se opção nodev está definida em /home"
(findmnt -n -o OPTIONS /home | grep -qw nodev) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[21] Verifique se opção nosuid está definida em /home"
(findmnt -n -o OPTIONS /home | grep -qw nosuid) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


# --- /var ---
echo -e "\n[22] Verifique se /var é uma partição separada"
(findmnt -kn /var | grep -q "/var") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[23] Verifique se opção nodev está definida em /var"
(findmnt -n -o OPTIONS /var | grep -qw nodev) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[24] Verifique se opção nosuid está definida em /var"
(findmnt -n -o OPTIONS /var | grep -qw nosuid) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


# --- /var/tmp ---
echo -e "\n[25] Verifique se /var/tmp é uma partição separada"
(findmnt -kn /var/tmp | grep -q "/var/tmp") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[26] Verifique se opção nodev está definida em /var/tmp"
(findmnt -n -o OPTIONS /var/tmp | grep -qw nodev) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[27] Verifique se opção nosuid está definida em /var/tmp"
(findmnt -n -o OPTIONS /var/tmp | grep -qw nosuid) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[28] Verifique se opção noexec está definida em /var/tmp"
(findmnt -n -o OPTIONS /var/tmp | grep -qw noexec) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


# --- /var/log ---
echo -e "\n[29] Verifique se /var/log é uma partição separada"
(findmnt -kn /var/log | grep -q "/var/log") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[30] Verifique se opção nodev está definida em /var/log"
(findmnt -n -o OPTIONS /var/log | grep -qw nodev) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[31] Verifique se opção nosuid está definida em /var/log"
(findmnt -n -o OPTIONS /var/log | grep -qw nosuid) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[32] Verifique se opção noexec está definida em /var/log"
(findmnt -n -o OPTIONS /var/log | grep -qw noexec) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


# --- /var/log/audit ---
echo -e "\n[33] Verifique se /var/log/audit é uma partição separada"
(findmnt -kn /var/log/audit | grep -q "/var/log/audit") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[34] Verifique se opção nodev está definida em /var/log/audit"
(findmnt -n -o OPTIONS /var/log/audit | grep -qw nodev) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[35] Verifique se opção nosuid está definida em /var/log/audit"
(findmnt -n -o OPTIONS /var/log/audit | grep -qw nosuid) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[36] Verifique se opção noexec está definida em /var/log/audit"
(findmnt -n -o OPTIONS /var/log/audit | grep -qw noexec) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [PLUS] Verifique se /UNIX está configurado com nodev,nosuid,noexec"
grep -qE '\s/UNIX(\s|$)' /etc/fstab && grep -E '\s/UNIX(\s|$)' /etc/fstab | grep -qw nodev && grep -E '\s/UNIX(\s|$)' /etc/fstab | grep -qw nosuid && grep -E '\s/UNIX(\s|$)' /etc/fstab | grep -qw noexec && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [PLUS] Verifique se /crash está configurado com nodev,nosuid,noexec"
grep -qE '\s/crash(\s|$)' /etc/fstab && grep -E '\s/crash(\s|$)' /etc/fstab | grep -qw nodev && grep -E '\s/crash(\s|$)' /etc/fstab | grep -qw nosuid && grep -E '\s/crash(\s|$)' /etc/fstab | grep -qw noexec && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [PLUS] Verifique se /historico está configurado com nodev,nosuid,noexec"
grep -qE '\s/historico(\s|$)' /etc/fstab && grep -E '\s/historico(\s|$)' /etc/fstab | grep -qw nodev && grep -E '\s/historico(\s|$)' /etc/fstab | grep -qw nosuid && grep -E '\s/historico(\s|$)' /etc/fstab | grep -qw noexec && echo "✅ APROVADO" || echo "⚠️ REPROVADO"