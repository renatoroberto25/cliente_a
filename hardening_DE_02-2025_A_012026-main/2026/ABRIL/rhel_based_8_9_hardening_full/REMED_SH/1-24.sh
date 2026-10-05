#!/bin/bash

echo "[1 – 24] Remediações Módulos do Kernel"
#cramfs squashfs udf hfs hfsplus jffs2 freevxfs overlay usb-storage dccp sctp rds tipc

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

MODFILE="/etc/modprobe.d/hardening.conf"
SYSCTLFILE="/etc/sysctl.d/99-hardening.conf"

touch "$MODFILE" "$SYSCTLFILE"

echo "[1-13] Desabilitar módulos do kernel"

backup "$MODFILE"

MODS="cramfs squashfs udf hfs hfsplus jffs2 freevxfs overlay usb-storage dccp sctp rds tipc"

for m in $MODS; do
    if ! grep -q "^install $m /bin/true" "$MODFILE" 2>/dev/null; then
        echo "install $m /bin/true" >> "$MODFILE"
        echo "blacklist $m"          >> "$MODFILE"
        echo "✔ módulo $m configurado"
    else
        echo "✔ módulo $m já estava configurado"
    fi

    # se carregado, descarrega
    lsmod | grep -q "^$m" && { modprobe -r "$m" 2>/dev/null && echo "✔ descarregado: $m"; }
done

echo "[14] Restringir core dumps"

backup "$SYSCTLFILE"

grep -q '^fs.suid_dumpable' "$SYSCTLFILE" 2>/dev/null && \
    sed -i 's/^fs.suid_dumpable.*/fs.suid_dumpable = 0/' "$SYSCTLFILE" || \
    echo "fs.suid_dumpable = 0" >> "$SYSCTLFILE"

sysctl -w fs.suid_dumpable=0
echo "✔ core dumps restritos"

echo "[15] ptrace_scope restrito"

backup "$SYSCTLFILE"

grep -q '^kernel.yama.ptrace_scope' "$SYSCTLFILE" 2>/dev/null && \
    sed -i 's/^kernel.yama.ptrace_scope.*/kernel.yama.ptrace_scope = 2/' "$SYSCTLFILE" || \
    echo "kernel.yama.ptrace_scope = 2" >> "$SYSCTLFILE"

sysctl -w kernel.yama.ptrace_scope=2
echo "✔ ptrace restrito"

echo "[16] NX/XD"
grep -q nx /proc/cpuinfo && echo "✔ Hardware suporta NX" || echo "⚠ Hardware sem NX – não há remediação via sistema"

echo "[17] ASLR habilitado"

backup "$SYSCTLFILE"

grep -q '^kernel.randomize_va_space' "$SYSCTLFILE" 2>/dev/null && \
    sed -i 's/^kernel.randomize_va_space.*/kernel.randomize_va_space = 2/' "$SYSCTLFILE" || \
    echo "kernel.randomize_va_space = 2" >> "$SYSCTLFILE"

sysctl -w kernel.randomize_va_space=2
echo "✔ ASLR ativado"

echo "[18] IOMMU proteção"

GRUB="/etc/default/grub"
backup "$GRUB"

if ! grep -q "iommu=on" "$GRUB"; then
    sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="iommu=on /' "$GRUB"
    grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
    echo "✔ IOMMU habilitado – reinício necessário"
else
    echo "✔ IOMMU já habilitado"
fi

echo "[19] perf_event restrito"

backup "$SYSCTLFILE"

grep -q '^kernel.perf_event_paranoid' "$SYSCTLFILE" 2>/dev/null && \
    sed -i 's/^kernel.perf_event_paranoid.*/kernel.perf_event_paranoid = 3/' "$SYSCTLFILE" || \
    echo "kernel.perf_event_paranoid = 3" >> "$SYSCTLFILE"

sysctl -w kernel.perf_event_paranoid=3
echo "✔ perf_event restrito"

echo "[20] dmesg restrito"

backup "$SYSCTLFILE"

grep -q '^kernel.dmesg_restrict' "$SYSCTLFILE" 2>/dev/null && \
    sed -i 's/^kernel.dmesg_restrict.*/kernel.dmesg_restrict = 1/' "$SYSCTLFILE" || \
    echo "kernel.dmesg_restrict = 1" >> "$SYSCTLFILE"

sysctl -w kernel.dmesg_restrict=1
echo "✔ dmesg restrito"

echo "[21] user namespace desabilitado"
backup "$SYSCTLFILE"
grep -q '^kernel.unprivileged_userns_clone' "$SYSCTLFILE" 2>/dev/null && \
    sed -i 's/^kernel.unprivileged_userns_clone.*/kernel.unprivileged_userns_clone = 0/' "$SYSCTLFILE" || \
    echo "kernel.unprivileged_userns_clone = 0" >> "$SYSCTLFILE"
if sysctl -w kernel.unprivileged_userns_clone=0 >/dev/null 2>&1; then
    echo "✔ user namespace desativado"
else
    echo "⚠ kernel.unprivileged_userns_clone não suportado neste sistema"
fi

echo "[22] protected_symlinks"

backup "$SYSCTLFILE"

grep -q '^fs.protected_symlinks' "$SYSCTLFILE" 2>/dev/null && \
    sed -i 's/^fs.protected_symlinks.*/fs.protected_symlinks = 1/' "$SYSCTLFILE" || \
    echo "fs.protected_symlinks = 1" >> "$SYSCTLFILE"

sysctl -w fs.protected_symlinks=1
echo "✔ symlinks protegidos"

echo "[23] protected_hardlinks"

backup "$SYSCTLFILE"

grep -q '^fs.protected_hardlinks' "$SYSCTLFILE" 2>/dev/null && \
    sed -i 's/^fs.protected_hardlinks.*/fs.protected_hardlinks = 1/' "$SYSCTLFILE" || \
    echo "fs.protected_hardlinks = 1" >> "$SYSCTLFILE"

sysctl -w fs.protected_hardlinks=1
echo "✔ hardlinks protegidos"

echo "[24] suid_dumpable=0 (reforço)"

grep -q '^fs.suid_dumpable' "$SYSCTLFILE" 2>/dev/null || \
    echo "fs.suid_dumpable = 0" >> "$SYSCTLFILE"

sysctl -w fs.suid_dumpable=0
echo "✔ suid_dumpable mantido em 0"

echo "OK"
exit 0
