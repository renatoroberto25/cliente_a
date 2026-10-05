#!/usr/bin/env bash
echo "[87] Habilitar assinaturas GPG (RHEL 7)"

YUMCONF="/etc/yum.conf"

backup() {
    [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

echo
echo "[YUM] Ajustando $YUMCONF"

if [ -f "$YUMCONF" ]; then
    backup "$YUMCONF"

    if grep -Eq '^\s*gpgcheck\s*=\s*1' "$YUMCONF"; then
        echo " gpgcheck já habilitado"
    else
        if grep -q '^\s*gpgcheck=' "$YUMCONF"; then
            sed -ri 's/^\s*gpgcheck=.*/gpgcheck=1/' "$YUMCONF"
        else
            echo "gpgcheck=1" >> "$YUMCONF"
        fi
        echo " gpgcheck ajustado para 1"
    fi

    if grep -Eq '^\s*localpkg_gpgcheck\s*=\s*1' "$YUMCONF"; then
        echo " localpkg_gpgcheck já habilitado"
    else
        if grep -q '^\s*localpkg_gpgcheck=' "$YUMCONF"; then
            sed -ri 's/^\s*localpkg_gpgcheck=.*/localpkg_gpgcheck=1/' "$YUMCONF"
        else
            echo "localpkg_gpgcheck=1" >> "$YUMCONF"
        fi
        echo " localpkg_gpgcheck ajustado para 1"
    fi
else
    echo " Arquivo yum.conf não encontrado"
fi

echo
echo "[REPO] Ajustando repositórios"

for repo in /etc/yum.repos.d/*.repo; do
    [ -f "$repo" ] || continue

    backup "$repo"

    if grep -Eq '^\s*gpgcheck\s*=\s*1' "$repo"; then
        echo " $repo já protegido"
    else
        if grep -q '^\s*gpgcheck=' "$repo"; then
            sed -ri 's/^\s*gpgcheck=.*/gpgcheck=1/' "$repo"
        else
            echo "gpgcheck=1" >> "$repo"
        fi
        echo " $repo ajustado"
    fi
done

echo
echo "[87] Concluído"

echo "[88] Patches de segurança"
echo " Aplicação de patches deve ser realizada via processo oficial de patching."
echo " Este controle é informativo no hardening."
