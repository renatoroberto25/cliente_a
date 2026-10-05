#!/usr/bin/env bash
echo -e "\n[87] Remediação: habilitar assinaturas GPG"

YUMCONF="/etc/yum.conf"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

# Forçar gpgcheck=1 em /etc/yum.conf
backup "$YUMCONF"
if grep -q '^gpgcheck=' "$YUMCONF"; then
    sed -i 's/^gpgcheck=.*/gpgcheck=1/' "$YUMCONF"
else
    echo "gpgcheck=1" >> "$YUMCONF"
fi

# Forçar localpkg_gpgcheck=1
if grep -q '^localpkg_gpgcheck=' "$YUMCONF"; then
    sed -i 's/^localpkg_gpgcheck=.*/localpkg_gpgcheck=1/' "$YUMCONF"
else
    echo "localpkg_gpgcheck=1" >> "$YUMCONF"
fi

# Ajustar todos os repositórios
for repo in /etc/yum.repos.d/*.repo; do
    backup "$repo"
    if grep -q '^gpgcheck=' "$repo"; then
        sed -i 's/^gpgcheck=.*/gpgcheck=1/' "$repo"
    else
        echo "gpgcheck=1" >> "$repo"
    fi
done

echo "OK"
exit 0
