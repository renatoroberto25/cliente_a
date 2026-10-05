#!/bin/bash

# =========================
# 1–13 Kernel modules
# =========================

echo -e "\n[1] Desabilitar módulo cramfs"
modinfo cramfs 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[2] Desabilitar módulo squashfs"
modinfo squashfs 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[3] Desabilitar módulo udf"
modinfo udf 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[4] Desabilitar módulo hfs"
modinfo hfs 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[5] Desabilitar módulo hfsplus"
modinfo hfsplus 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[6] Desabilitar módulo jffs2"
modinfo jffs2 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[7] Desabilitar módulo freevxfs"
modinfo freevxfs 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[8] Desabilitar módulo overlayfs"
modinfo overlay 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[9] Desabilitar módulo usb-storage"
modinfo usb-storage 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[10] Desabilitar módulo DCCP"
modinfo dccp 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[11] Desabilitar módulo SCTP"
modinfo sctp 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[12] Desabilitar módulo RDS"
modinfo rds 2>/dev/null || echo "WARNING: modinfo sem output"

echo -e "\n[13] Desabilitar módulo TIPC"
modinfo tipc 2>/dev/null || echo "WARNING: modinfo sem output"

# =========================
# 14–24 Kernel / sysctl
# =========================

echo -e "\n[14] Core dumps restritos"
ulimit -c; sysctl fs.suid_dumpable || echo "WARNING: sysctl sem output"

echo -e "\n[15] ptrace_scope restrito"
sysctl kernel.yama.ptrace_scope || echo "WARNING: sysctl sem output"

echo -e "\n[16] NX/XD ativo"
grep -w nx /proc/cpuinfo; dmesg | grep -i nx || echo "WARNING: nenhuma evidência NX"

echo -e "\n[17] ASLR habilitado"
sysctl kernel.randomize_va_space || echo "WARNING: sysctl sem output"

echo -e "\n[18] IOMMU proteção"
grep -i iommu /proc/cmdline || echo "WARNING: cmdline sem iommu"

echo -e "\n[19] perf_event restrito"
sysctl kernel.perf_event_paranoid || echo "WARNING: sysctl sem output"

echo -e "\n[20] dmesg restrito"
sysctl kernel.dmesg_restrict || echo "WARNING: sysctl sem output"

echo -e "\n[21] user namespace desabilitado"
sysctl kernel.unprivileged_userns_clone || echo "WARNING: sysctl sem output"

echo -e "\n[22] protected_symlinks"
sysctl fs.protected_symlinks || echo "WARNING: sysctl sem output"

echo -e "\n[23] protected_hardlinks"
sysctl fs.protected_hardlinks || echo "WARNING: sysctl sem output"

echo -e "\n[24] suid_dumpable=0"
sysctl fs.suid_dumpable || echo "WARNING: sysctl sem output"

# =========================
# 25–34 Partições dedicadas
# =========================

echo -e "\n[25] Partição dedicada para /tmp"
findmnt -kn /tmp || echo "WARNING: mount não encontrado"

echo -e "\n[26] Partição dedicada para /dev/shm"
findmnt -kn /dev/shm || echo "WARNING: mount não encontrado"

echo -e "\n[27] Partição dedicada para /var"
findmnt -kn /var || echo "WARNING: mount não encontrado"

echo -e "\n[28] Partição dedicada para /var/tmp"
findmnt -kn /var/tmp || echo "WARNING: mount não encontrado"

echo -e "\n[29] Partição dedicada para /var/log"
findmnt -kn /var/log || echo "WARNING: mount não encontrado"

echo -e "\n[30] Partição dedicada para /var/log/audit"
findmnt -kn /var/log/audit || echo "WARNING: mount não encontrado"

echo -e "\n[31] Partição dedicada para /home"
findmnt -kn /home || echo "WARNING: mount não encontrado"

echo -e "\n[32] Partição dedicada para /historico"
findmnt -kn /historico || echo "WARNING: mount não encontrado"

echo -e "\n[33] Partição dedicada para /crash"
findmnt -kn /crash || echo "WARNING: mount não encontrado"

echo -e "\n[34] Partição dedicada para /UNIX"
findmnt -kn /UNIX || echo "WARNING: mount não encontrado"

# =========================
# 35–43 Opções de montagem
# =========================

echo -e "\n[35] Montagem segura de partições e mídia removível"
grep -E 'nodev|nosuid|noexec' /etc/fstab || echo "WARNING: nenhuma opção encontrada"

echo -e "\n[36] Opções de montagem seguras em partições críticas"
findmnt -n /var || echo "WARNING: sem output"

echo -e "\n[37] Opções de montagem seguras em /tmp"
findmnt -n /tmp || echo "WARNING: sem output"

echo -e "\n[38] Opções de montagem seguras em /dev/shm"
findmnt -n /dev/shm || echo "WARNING: sem output"

echo -e "\n[39] Opções de montagem seguras em /var/tmp"
findmnt -n /var/tmp || echo "WARNING: sem output"

echo -e "\n[40] Opções de montagem seguras em /var/log"
findmnt -n /var/log || echo "WARNING: sem output"

echo -e "\n[41] Opções de montagem seguras em /var/log/audit"
findmnt -n /var/log/audit || echo "WARNING: sem output"

echo -e "\n[42] Opções de montagem seguras em /home"
findmnt -n /home || echo "WARNING: sem output"

echo -e "\n[43] Opções de montagem seguras em mídias removíveis"
findmnt -rno TARGET,OPTIONS | grep -E '/media|/run/media' || echo "WARNING: nenhuma mídia detectada"
