#!/usr/bin/env bash

echo -e "\n[35 - 43] Remediação de opções de montagem seguras (RHEL 7 – FULL)"

FSTAB="/etc/fstab"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

apply_opt() {
    local MNT="$1"
    local OPTS="$2"

    # só remedia se for partição REAL
    if ! findmnt -kn "$MNT" >/dev/null 2>&1; then
        echo " $MNT não é partição dedicada – ignorado"
        return
    fi

    local LINE
    LINE=$(grep -E "[[:space:]]$MNT[[:space:]]" "$FSTAB" || true)

    if [ -z "$LINE" ]; then
        echo " $MNT montado sem fstab – não modificado"
        return
    fi

    local CURRENT
    CURRENT=$(echo "$LINE" | awk '{print $4}')

    local OK=1
    for o in $(echo "$OPTS" | tr ',' ' '); do
        echo "$CURRENT" | grep -qw "$o" || OK=0
    done

    if [ $OK -eq 1 ]; then
        echo " $MNT já possui $OPTS"
        return
    fi

    backup "$FSTAB"

    awk -v tgt="$MNT" -v opts="$OPTS" '
        $2==tgt && $0 !~ /^#/ {
            printf "%s\t%s\t%s\t%s\t0\t0\n", $1,$2,$3,opts
            next
        }
        {print}
    ' "$FSTAB" > "${FSTAB}.tmp" && mv "${FSTAB}.tmp" "$FSTAB"

    echo " aplicado $OPTS em $MNT (reboot necessário)"
}

echo -e "\n[35] Mídias removíveis"
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
echo "ℹ /home fora do escopo (risco operacional)"

echo -e "\n[43] Mídias removíveis (reforço)"
apply_opt "/media" "nodev,nosuid,noexec"
apply_opt "/run/media" "nodev,nosuid,noexec"

echo -e "\n[POST] Garantir SSH privilege separation (RHEL 7)"
mkdir -p /var/empty/sshd
chown root:root /var/empty /var/empty/sshd
chmod 755 /var/empty /var/empty/sshd

/usr/sbin/sshd -t >/dev/null 2>&1 \
  && echo " sshd validado" \
  || echo " sshd inválido – revisar antes do reboot"
