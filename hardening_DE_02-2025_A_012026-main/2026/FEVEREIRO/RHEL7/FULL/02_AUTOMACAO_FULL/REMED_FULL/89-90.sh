#!/usr/bin/env bash
echo "[89 - 90] Remediação: Time Sync e Cron/At (RHEL 7)"

backup() {
    [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

echo
echo "[89] Garantir apenas um daemon de time sync (chrony preferido)"

ACTIVE_COUNT=$(systemctl is-active chronyd ntpd 2>/dev/null | grep -c '^active$')

if [ "$ACTIVE_COUNT" -eq 1 ] && systemctl is-active --quiet chronyd 2>/dev/null; then
    echo " Sistema já conforme (chronyd único ativo)"
else
    if ! rpm -q chrony &>/dev/null; then
        yum install -y chrony >/dev/null 2>&1
        echo " chrony instalado"
    fi

    if systemctl is-active --quiet ntpd 2>/dev/null; then
        systemctl stop ntpd >/dev/null 2>&1
        systemctl disable ntpd >/dev/null 2>&1
        echo " ntpd desabilitado"
    fi

    if systemctl list-unit-files | grep -q '^systemd-timesyncd\.service'; then
        systemctl stop systemd-timesyncd 2>/dev/null
        systemctl disable systemd-timesyncd 2>/dev/null
        echo " systemd-timesyncd desabilitado"
    fi

    systemctl enable chronyd --now >/dev/null 2>&1
    echo " chronyd habilitado como daemon único"
fi

echo
echo "[90] Garantir cron/at restritos"

if [ -f /etc/cron.allow ]; then
    PERM=$(stat -Lc '%a %U %G' /etc/cron.allow 2>/dev/null)
    if echo "$PERM" | grep -Eq '^640 root (root|crontab)$'; then
        echo " /etc/cron.allow já seguro"
    else
        backup /etc/cron.allow
        chown root:root /etc/cron.allow
        chmod 640 /etc/cron.allow
        echo " Permissões de /etc/cron.allow ajustadas"
    fi
else
    echo "root" > /etc/cron.allow
    chown root:root /etc/cron.allow
    chmod 640 /etc/cron.allow
    echo " /etc/cron.allow criado e protegido"
fi

echo
echo "[89 - 90] Concluído"
