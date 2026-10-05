#!/usr/bin/env bash

echo "[35 - 43] Remediação de opções de montagem seguras (idempotente)"

FSTAB="/etc/fstab"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

apply_opt() {
    local MNT="$1"
    local OPTS="$2"

    # só remedia se for partição REAL (montada separadamente)
    if ! findmnt -kn "$MNT" >/dev/null 2>&1; then
        echo "⚠️ $MNT não é uma partição real – ignorando"
        return
    fi

    # obtém entrada atual no fstab
    local LINE
    LINE=$(grep -E "[[:space:]]$MNT[[:space:]]" "$FSTAB" || true)

    if [ -z "$LINE" ]; then
        echo "⚠️ $MNT montado mas sem linha no fstab – não modificado"
        return
    fi

    local CURRENT
    CURRENT=$(echo "$LINE" | awk '{print $4}')

    # verifica se já possui tudo
    local OK=1
    for o in $(echo "$OPTS" | tr ',' ' '); do
        echo "$CURRENT" | grep -qw "$o" || OK=0
    done

    if [ $OK -eq 1 ]; then
        echo "✔ $MNT já possui $OPTS"
        return
    fi

    # remediação idempotente
    backup "$FSTAB"

    # substitui apenas campo de opções, mantendo dispositivo e tipo
    awk -v tgt="$MNT" -v opts="$OPTS" '
        $2==tgt && $0 !~ /^#/ {
            printf "%s\t%s\t%s\t%s\t0\t0\n", $1,$2,$3,opts
            next
        }
        {print}
    ' "$FSTAB" > "${FSTAB}.tmp" && mv "${FSTAB}.tmp" "$FSTAB"

    echo "✔ aplicado $OPTS em $MNT"
}

echo -e "\n[35] Opções seguras para mídias removíveis"
apply_opt "/media" "nodev,nosuid,noexec"
apply_opt "/run/media" "nodev,nosuid,noexec"

echo -e "\n[36] /var"
apply_opt "/var" "nodev,nosuid,noexec"

echo -e "\n[37] /tmp"
apply_opt "/tmp" "nodev,nosuid,noexec"

echo -e "\n[38] /dev/shm"
apply_opt "/dev/shm" "nodev,nosuid,noexec"

echo -e "\n[39] /var/tmp"
apply_opt "/var/tmp" "nodev,nosuid,noexec"

echo -e "\n[40] /var/log"
apply_opt "/var/log" "nodev,nosuid,noexec"

echo -e "\n[41] /var/log/audit"
apply_opt "/var/log/audit" "nodev,nosuid,noexec"

echo -e "\n[42] /home"
apply_opt "/home" "nodev"

echo -e "\n[43] Mídias removíveis"
apply_opt "/media" "nodev,nosuid,noexec"
apply_opt "/run/media" "nodev,nosuid,noexec"


echo "OK"
exit 0
