#!/usr/bin/env bash
set -euo pipefail

echo -e "\n [1] Verifique se o módulo do kernel do CRAMFS não está disponível"
( (modinfo cramfs &>/dev/null && modprobe --showconfig | grep -E '\<(install|blacklist)[[:space:]]+cramfs\>' >/dev/null && ! lsmod | grep -q '^cramfs') || (! modinfo cramfs &>/dev/null) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [2] Verifique se o módulo do kernel do SQUASHFS não está disponível"
( (modinfo squashfs &>/dev/null && modprobe --showconfig | grep -E '\<(install|blacklist)[[:space:]]+squashfs\>' >/dev/null && ! lsmod | grep -q '^squashfs') || (! modinfo squashfs &>/dev/null) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [3] Verifique se o módulo do kernel do UDF não está disponível"
( (modinfo udf &>/dev/null && modprobe --showconfig | grep -E '\<(install|blacklist)[[:space:]]+udf\>' >/dev/null && ! lsmod | grep -q '^udf') || (! modinfo udf &>/dev/null) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [4] Verifique se /tmp está configurado"
grep -qE '\s/tmp(\s|$)' /etc/fstab && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [5] Verifique se a opção noexec está configurada em /tmp"
(grep -qE '\s/tmp(\s|$)' /etc/fstab && grep -qw noexec <(grep -E '\s/tmp(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [6] Verifique se a opção nodev está configurada em /tmp"
(grep -qE '\s/tmp(\s|$)' /etc/fstab && grep -qw nodev <(grep -E '\s/tmp(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [7] Verifique se a opção nosuid está configurada em /tmp"
(grep -qE '\s/tmp(\s|$)' /etc/fstab && grep -qw nosuid <(grep -E '\s/tmp(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [8] Verifique se /dev/shm está configurado"
grep -qE '\s/dev/shm(\s|$)' /etc/fstab && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [9] Verifique se a opção noexec está configurada em /dev/shm"
(grep -qE '\s/dev/shm(\s|$)' /etc/fstab && grep -qw noexec <(grep -E '\s/dev/shm(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [10] Verifique se a opção nodev está configurada em /dev/shm"
(grep -qE '\s/dev/shm(\s|$)' /etc/fstab && grep -qw nodev <(grep -E '\s/dev/shm(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [11] Verifique se a opção nosuid está configurada em /dev/shm"
(grep -qE '\s/dev/shm(\s|$)' /etc/fstab && grep -qw nosuid <(grep -E '\s/dev/shm(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [12] Verifique se existe uma partição separada para /var"
mount | grep -qw "on /var " && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [13] Verifique se existe uma partição separada para /var/tmp"
mount | grep -qw "on /var/tmp " && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [14] Verifique se a opção noexec está configurada em /var/tmp"
(grep -qE '\s/var/tmp(\s|$)' /etc/fstab && grep -qw noexec <(grep -E '\s/var/tmp(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [15] Verifique se a opção nodev está configurada em /var/tmp"
(grep -qE '\s/var/tmp(\s|$)' /etc/fstab && grep -qw nodev <(grep -E '\s/var/tmp(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [16] Verifique se a opção nosuid está configurada em /var/tmp"
(grep -qE '\s/var/tmp(\s|$)' /etc/fstab && grep -qw nosuid <(grep -E '\s/var/tmp(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [17] Verifique se existe uma partição separada para /var/log"
mount | grep -qw "on /var/log " && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [18] Verifique se existe uma partição separada para /var/log/audit"
mount | grep -qw "on /var/log/audit " && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [19] Verifique se existe uma partição separada para /home"
mount | grep -qw "on /home " && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [20] Verifique se a opção nodev está configurada em /home"
(grep -qE '\s/home(\s|$)' /etc/fstab && grep -qw nodev <(grep -E '\s/home(\s|$)' /etc/fstab)) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [21] Verifique se as mídias removíveis incluem a opção noexec"
(grep -E 'vfat|iso9660|udf' /etc/fstab | grep -qw noexec) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [22] Verifique se as mídias removíveis incluem a opção nodev"
(grep -E 'vfat|iso9660|udf' /etc/fstab | grep -qw nodev) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [23] Verifique se as mídias removíveis incluem a opção nosuid"
(grep -E 'vfat|iso9660|udf' /etc/fstab | grep -qw nosuid) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [24] Verifique se o sticky bit está definido em todos os diretórios world-writable"
df --local -P | awk 'NR!=1 {print $6}' | xargs -r -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | grep -q . && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n [25] Verifique se o automount está desabilitado"
systemctl is-enabled autofs &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n [26] Verifique se o módulo de armazenamento USB está desativado"
( (modinfo usb-storage &>/dev/null && (modprobe --showconfig | grep -E '\<(install|blacklist)[[:space:]]+usb-storage\>' >/dev/null || modprobe --showconfig | grep -E '\<(install|blacklist)[[:space:]]+usb_storage\>' >/dev/null) && ! (lsmod | grep -q '^usb_storage' || lsmod | grep -q '^usb-storage')) || (! modinfo usb-storage &>/dev/null && ! modinfo usb_storage &>/dev/null) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [PLUS] Verifique se /UNIX está configurado com nodev,nosuid,noexec"
grep -qE '\s/UNIX(\s|$)' /etc/fstab && grep -E '\s/UNIX(\s|$)' /etc/fstab | grep -qw nodev && grep -E '\s/UNIX(\s|$)' /etc/fstab | grep -qw nosuid && grep -E '\s/UNIX(\s|$)' /etc/fstab | grep -qw noexec && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [PLUS] Verifique se /crash está configurado com nodev,nosuid,noexec"
grep -qE '\s/crash(\s|$)' /etc/fstab && grep -E '\s/crash(\s|$)' /etc/fstab | grep -qw nodev && grep -E '\s/crash(\s|$)' /etc/fstab | grep -qw nosuid && grep -E '\s/crash(\s|$)' /etc/fstab | grep -qw noexec && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [PLUS] Verifique se /historico está configurado com nodev,nosuid,noexec"
grep -qE '\s/historico(\s|$)' /etc/fstab && grep -E '\s/historico(\s|$)' /etc/fstab | grep -qw nodev && grep -E '\s/historico(\s|$)' /etc/fstab | grep -qw nosuid && grep -E '\s/historico(\s|$)' /etc/fstab | grep -qw noexec && echo "✅ APROVADO" || echo "⚠️ REPROVADO"