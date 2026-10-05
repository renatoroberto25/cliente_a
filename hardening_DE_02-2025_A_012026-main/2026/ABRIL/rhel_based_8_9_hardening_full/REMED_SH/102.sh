#!/usr/bin/env bash
echo "[102] Remediação: Desabilitar módulos Wireless/Bluetooth"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

for m in bluetooth iwlwifi; do
    if lsmod | grep -q "^$m"; then
        modprobe -r "$m" 2>/dev/null
        echo "✔ removido: $m"
    fi
done

MODFILE="/etc/modprobe.d/hardening-wireless.conf"

backup "$MODFILE"

echo "blacklist bluetooth" > "$MODFILE"
echo "blacklist iwlwifi" >> "$MODFILE"

echo "install bluetooth /bin/true" >> "$MODFILE"
echo "install iwlwifi /bin/true" >> "$MODFILE"

echo "OK"
