#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: modulos de kernel e sysctl seguros"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"
MODFILE="/etc/modprobe.d/99-hitss-hardening.conf"
SYSCTLFILE="/etc/sysctl.d/99-hitss-hardening.conf"
LIMITSFILE="/etc/security/limits.d/99-hitss-coredump.conf"

backup_file() {
    local file="$1"
    [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null || true
}

ensure_file() {
    local file="$1"
    local dir
    dir="$(dirname "$file")"
    if [ ! -d "$dir" ]; then
        echo "WARN: diretorio ausente: $dir"
        return 1
    fi
    [ -e "$file" ] || touch "$file"
}

set_or_replace() {
    local file="$1" key="$2" value="$3" pattern
    pattern="${key//./\\.}"
    if grep -Eq "^[[:space:]]*${pattern}[[:space:]]*=" "$file" 2>/dev/null; then
        sed -i "s|^[[:space:]]*${pattern}[[:space:]]*=.*|${key} = ${value}|" "$file"
    else
        printf '%s = %s\n' "$key" "$value" >> "$file"
    fi
}

sysctl_supported() {
    [ -e "/proc/sys/${1//./\/}" ]
}

set_sysctl_control() {
    local id="$1" label="$2" key="$3" value="$4"
    echo "[$id] $label"

    if ! sysctl_supported "$key"; then
        echo "SKIP: $key nao suportado neste kernel"
        return
    fi

    if ensure_file "$SYSCTLFILE"; then
        set_or_replace "$SYSCTLFILE" "$key" "$value"
    else
        echo "WARN: $key=$value nao foi persistido em $SYSCTLFILE"
    fi

    if sysctl -w "$key=$value" >/dev/null 2>&1; then
        echo "OK: $key=$value aplicado e persistido"
    else
        echo "WARN: $key=$value persistido, mas runtime nao aceitou aplicacao imediata"
    fi
}

set_kernel_cmdline_arg() {
    local id="$1" label="$2" arg="$3"
    echo "[$id] $label"

    if grep -qw "$arg" /proc/cmdline 2>/dev/null; then
        echo "OK: $arg ja presente em /proc/cmdline"
        return
    fi

    if command -v grubby >/dev/null 2>&1; then
        if grubby --update-kernel=ALL --args="$arg" >/dev/null 2>&1; then
            echo "OK: $arg persistido via grubby; requer reboot para refletir no audit"
        else
            echo "WARN: falha ao persistir $arg via grubby"
        fi
    else
        echo "SKIP: $arg exige ajuste de bootloader e reboot; grubby nao disponivel"
    fi
}

set_coredump_limits() {
    echo "[14] Limite de core dump"
    if ensure_file "$LIMITSFILE"; then
        backup_file "$LIMITSFILE"
        grep -Eq '^[*][[:space:]]+hard[[:space:]]+core[[:space:]]+0$' "$LIMITSFILE" 2>/dev/null ||
            printf '* hard core 0\n' >> "$LIMITSFILE"
        grep -Eq '^[*][[:space:]]+soft[[:space:]]+core[[:space:]]+0$' "$LIMITSFILE" 2>/dev/null ||
            printf '* soft core 0\n' >> "$LIMITSFILE"
        echo "OK: limites de core dump persistidos em $LIMITSFILE"
    fi
}

block_module() {
    local id="$1" mod="$2"
    echo "[$id] Bloqueio $mod"

    grep -Eq "^[[:space:]]*install[[:space:]]+${mod}[[:space:]]+/bin/(true|false)" "$MODFILE" 2>/dev/null ||
        printf 'install %s /bin/true\n' "$mod" >> "$MODFILE"
    grep -Eq "^[[:space:]]*blacklist[[:space:]]+${mod}\b" "$MODFILE" 2>/dev/null ||
        printf 'blacklist %s\n' "$mod" >> "$MODFILE"

    if lsmod 2>/dev/null | awk '{print $1}' | grep -qx "$mod"; then
        echo "WARN: modulo $mod esta carregado; bloqueio persistido, remocao runtime exige janela validada"
    else
        echo "OK: modulo $mod bloqueado"
    fi
}

if ensure_file "$MODFILE"; then
    backup_file "$MODFILE"
    block_module 1 cramfs
    block_module 4 hfs
    block_module 5 hfsplus
    block_module 6 jffs2
    block_module 7 freevxfs
    block_module 10 dccp
    block_module 12 rds
    block_module 13 tipc
else
    echo "WARN: bloqueio persistente de modulos ignorado; $MODFILE indisponivel"
fi

ensure_file "$SYSCTLFILE" && backup_file "$SYSCTLFILE"

set_sysctl_control 14 "Core dumps restritos" fs.suid_dumpable 0
set_coredump_limits
set_sysctl_control 15 "ptrace_scope restrito" kernel.yama.ptrace_scope 1

echo "[16] NX/XD ativo"
echo "SKIP: NX/XD depende de suporte de CPU/BIOS/kernel; sem remediacao shell segura"

set_sysctl_control 17 "ASLR habilitado" kernel.randomize_va_space 2
set_kernel_cmdline_arg 18 "IOMMU ativo" iommu=on
echo "[21] User namespace desabilitado"
echo "SKIP: desabilitar user namespaces pode quebrar containers rootless; validar por perfil do servidor"
set_sysctl_control 22 "Symlinks protegidos" fs.protected_symlinks 1
set_sysctl_control 24 "suid_dumpable desabilitado" fs.suid_dumpable 0

echo "OK"
exit 0
