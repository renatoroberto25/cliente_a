#!/bin/bash
#
# HITSS – Remediação 01–40
# Ubuntu 16.04
#

set -u

TS="$(date +%Y%m%d-%H%M%S)"
SYSCTL_FILE="/etc/sysctl.d/99-hitss-hardening.conf"
MODPROBE_FILE="/etc/modprobe.d/hitss-hardening.conf"
FSTAB="/etc/fstab"

# -------------------------
# Utilitários
# -------------------------

backup_file() {
    local f="$1"
    if [ -f "$f" ]; then
        cp -p "$f" "${f}.hitss-backup-${TS}"
        echo "Backup criado: ${f}.hitss-backup-${TS}"
    fi
}

ensure_sysctl() {
    local key="$1"
    local expected="$2"

    local current
    current="$(sysctl -n "$key" 2>/dev/null || echo "")"

    if [ "$current" = "$expected" ]; then
        echo "[$key] já conforme ($current)"
        return
    fi

    echo "[$key] não conforme (atual: ${current:-N/A}) – ajustando para $expected"

    backup_file "$SYSCTL_FILE"

    grep -q "^${key}\b" "$SYSCTL_FILE" 2>/dev/null \
        && sed -i "s|^${key}.*|${key} = ${expected}|" "$SYSCTL_FILE" \
        || echo "${key} = ${expected}" >> "$SYSCTL_FILE"

    sysctl -w "${key}=${expected}" >/dev/null
}

disable_module() {
    local mod="$1"

    if ! modinfo "$mod" &>/dev/null; then
        echo "[$mod] módulo inexistente – sem ação"
        return
    fi

    echo "[$mod] módulo presente – garantindo desativação"

    backup_file "$MODPROBE_FILE"

    grep -q "^blacklist ${mod}\b" "$MODPROBE_FILE" 2>/dev/null || \
        echo "blacklist ${mod}" >> "$MODPROBE_FILE"

    grep -q "^install ${mod}\b" "$MODPROBE_FILE" 2>/dev/null || \
        echo "install ${mod} /bin/true" >> "$MODPROBE_FILE"

    if lsmod | grep -q "^${mod}\b"; then
        echo "[$mod] carregado – tentando remover"
        rmmod "$mod" 2>/dev/null || echo "[$mod] não foi possível remover agora"
    fi
}

ensure_mount_opts() {
    local mp="$1"
    local required="$2"   # ex: nodev,nosuid,noexec

    if ! findmnt -kn "$mp" &>/dev/null; then
        echo "[$mp] não é ponto de montagem – sem remediação automática"
        return
    fi

    local current
    current="$(findmnt -n -o OPTIONS "$mp")"

    local missing=""
    IFS=',' read -ra req <<< "$required"
    for o in "${req[@]}"; do
        echo "$current" | grep -qw "$o" || missing+="${o},"
    done

    if [ -z "$missing" ]; then
        echo "[$mp] opções já conformes ($current)"
        return
    fi

    missing="${missing%,}"
    echo "[$mp] opções faltantes: $missing – corrigindo fstab"

    backup_file "$FSTAB"

    sed -i "/[[:space:]]${mp}[[:space:]]/ s|\(\s\+\)\([^[:space:]]\+\)$|\1\2,${missing}|" "$FSTAB"
}

# =========================
# 1–13 Kernel modules
# =========================

disable_module cramfs
disable_module squashfs
disable_module udf
disable_module hfs
disable_module hfsplus
disable_module jffs2
disable_module freevxfs
disable_module overlay
disable_module usb-storage
disable_module dccp
disable_module sctp
disable_module rds
disable_module tipc

# =========================
# 14–24 Sysctl / Kernel
# =========================

ensure_sysctl fs.suid_dumpable 0
ensure_sysctl kernel.yama.ptrace_scope 1
ensure_sysctl kernel.randomize_va_space 2
ensure_sysctl kernel.perf_event_paranoid 1
ensure_sysctl kernel.dmesg_restrict 1
ensure_sysctl kernel.unprivileged_userns_clone 0
ensure_sysctl fs.protected_symlinks 1
ensure_sysctl fs.protected_hardlinks 1

# =========================
# 25–34 Partições dedicadas
# (AUDIT-only – nenhuma ação)
# =========================

echo "[Partições dedicadas] Sem remediação automática (layout de disco)"

# =========================
# 35–43 Opções de montagem
# =========================

ensure_mount_opts /tmp "nodev,nosuid,noexec"
ensure_mount_opts /dev/shm "nodev,nosuid,noexec"
ensure_mount_opts /var "nodev"
ensure_mount_opts /var/tmp "nodev,nosuid,noexec"
ensure_mount_opts /var/log "nodev"
ensure_mount_opts /var/log/audit "nodev"
ensure_mount_opts /home "nodev"

echo "Remediação HITSS 01–40 concluída"
