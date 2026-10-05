#!/usr/bin/env bash
set -u

echo "[102] Remediacao: wireless e bluetooth"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"
MODFILE="/etc/modprobe.d/99-hitss-wireless.conf"

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

block_module() {
    local mod="$1"
    grep -Eq "^[[:space:]]*blacklist[[:space:]]+${mod}\b" "$MODFILE" 2>/dev/null ||
        printf 'blacklist %s\n' "$mod" >> "$MODFILE"
    grep -Eq "^[[:space:]]*install[[:space:]]+${mod}[[:space:]]+/bin/(true|false)" "$MODFILE" 2>/dev/null ||
        printf 'install %s /bin/true\n' "$mod" >> "$MODFILE"

    if lsmod 2>/dev/null | awk '{print $1}' | grep -qx "$mod"; then
        echo "WARN: modulo $mod esta carregado; bloqueio persistido para o proximo boot, sem interromper a conectividade atual"
    else
        echo "OK: modulo $mod bloqueado"
    fi
}

echo "[102] Wireless/Bluetooth desabilitados"
ensure_file "$MODFILE" || exit 0
backup_file "$MODFILE"
block_module bluetooth
block_module btusb
block_module btrtl
block_module btintel
block_module btbcm
block_module iwlwifi
block_module mac80211
block_module cfg80211

echo "OK"
exit 0
