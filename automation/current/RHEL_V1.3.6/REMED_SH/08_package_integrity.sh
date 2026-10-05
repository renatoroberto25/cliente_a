#!/usr/bin/env bash
set -u

echo "[87] Remediacao: verificacao GPG de pacotes"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"

backup_file() {
    local file="$1"
    [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null || true
}

set_key_value() {
    local file="$1" key="$2" value="$3"
    if [ ! -f "$file" ]; then
        echo "SKIP: $file nao existe"
        return
    fi

    backup_file "$file"
    if grep -Eq "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
        sed -i "s|^[[:space:]]*${key}[[:space:]]*=.*|${key}=${value}|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
    echo "OK: $key=$value definido em $file"
}

set_repo_gpgcheck() {
    local repo="$1"
    backup_file "$repo"
    if grep -Eq '^[[:space:]]*gpgcheck[[:space:]]*=' "$repo"; then
        sed -i 's|^[[:space:]]*gpgcheck[[:space:]]*=.*|gpgcheck=1|' "$repo"
    else
        printf '\ngpgcheck=1\n' >> "$repo"
    fi
    echo "OK: gpgcheck=1 definido em $repo"
}

set_key_value /etc/yum.conf gpgcheck 1
set_key_value /etc/yum.conf localpkg_gpgcheck 1
set_key_value /etc/dnf/dnf.conf gpgcheck 1
set_key_value /etc/dnf/dnf.conf localpkg_gpgcheck 1

found_repo=0
for repo in /etc/yum.repos.d/*.repo; do
    [ -e "$repo" ] || continue
    found_repo=1
    set_repo_gpgcheck "$repo"
done

[ "$found_repo" -eq 0 ] && echo "SKIP: nenhum arquivo .repo encontrado em /etc/yum.repos.d"

echo "OK"
exit 0
