#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: hardening de rede via sysctl"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"
SYSCTL="/etc/sysctl.d/99-hitss-network.conf"

backup_file() {
    local file="$1"
    [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null || true
}

ensure_file() {
    local file="$1" dir
    dir="$(dirname "$file")"
    if [ ! -d "$dir" ]; then
        echo "WARN: diretorio ausente: $dir"
        return 1
    fi
    [ -e "$file" ] || touch "$file"
}

sysctl_supported() {
    [ -e "/proc/sys/${1//./\/}" ]
}

set_or_replace() {
    local key="$1" val="$2" pattern
    pattern="${key//./\\.}"
    if grep -Eq "^[[:space:]]*${pattern}[[:space:]]*=" "$SYSCTL" 2>/dev/null; then
        sed -i "s|^[[:space:]]*${pattern}[[:space:]]*=.*|${key} = ${val}|" "$SYSCTL"
    else
        printf '%s = %s\n' "$key" "$val" >> "$SYSCTL"
    fi
}

set_sysctl() {
    local key="$1" val="$2"
    if ! sysctl_supported "$key"; then
        echo "SKIP: $key nao suportado neste kernel"
        return
    fi

    set_or_replace "$key" "$val"
    if sysctl -w "$key=$val" >/dev/null 2>&1; then
        echo "OK: $key=$val aplicado e persistido"
    else
        echo "WARN: $key=$val persistido, mas runtime nao aceitou aplicacao imediata"
    fi
}

ensure_file "$SYSCTL" || exit 0
backup_file "$SYSCTL"

echo "[92] Redirecionamentos de pacotes desabilitados"
set_sysctl net.ipv4.conf.all.send_redirects 0
set_sysctl net.ipv4.conf.default.send_redirects 0

echo "[93] Source-routed packets bloqueados"
set_sysctl net.ipv4.conf.all.accept_source_route 0
set_sysctl net.ipv4.conf.default.accept_source_route 0

echo "[94] ICMP redirects bloqueados"
set_sysctl net.ipv4.conf.all.accept_redirects 0
set_sysctl net.ipv4.conf.default.accept_redirects 0
set_sysctl net.ipv4.conf.all.secure_redirects 0
set_sysctl net.ipv4.conf.default.secure_redirects 0

echo "[96] ICMP broadcast ignorado"
set_sysctl net.ipv4.icmp_echo_ignore_broadcasts 1

echo "[97] Respostas ICMP invalidas ignoradas"
set_sysctl net.ipv4.icmp_ignore_bogus_error_responses 1

echo "[98] SYN cookies habilitado"
set_sysctl net.ipv4.tcp_syncookies 1

echo "OK"
exit 0
