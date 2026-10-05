#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[75 - 86] Remediação controlada – Serviços e Policy"

backup() {
    [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

disable_mask() {
    local svc="$1"
    if systemctl list-unit-files 2>/dev/null | grep -q "^${svc}"; then
        systemctl stop "$svc" 2>/dev/null || true
        systemctl disable "$svc" 2>/dev/null || true
        systemctl mask "$svc" 2>/dev/null || true
        echo " ${svc} desabilitado e mascarado"
    else
        echo " ${svc} não encontrado"
    fi
}

remove_pkg() {
    local pkg="$1"
    if rpm -q "$pkg" &>/dev/null; then
        if command -v dnf >/dev/null 2>&1; then
            dnf remove -y "$pkg" >/dev/null 2>&1
        else
            yum remove -y "$pkg" >/dev/null 2>&1
        fi
        echo " ${pkg} removido"
    else
        echo " ${pkg} não instalado"
    fi
}

echo -e "\n[75] MTA em modo local-only"

POSTFIX="/etc/postfix/main.cf"
if [ -f "$POSTFIX" ]; then
    backup "$POSTFIX"
    if grep -q '^inet_interfaces' "$POSTFIX"; then
        sed -i 's/^inet_interfaces.*/inet_interfaces = loopback-only/' "$POSTFIX"
    else
        echo "inet_interfaces = loopback-only" >> "$POSTFIX"
    fi
    systemctl restart postfix 2>/dev/null || true
    echo " Postfix ajustado para loopback-only"
else
    echo " Postfix não instalado"
fi

echo -e "\n[76] NFS server controlado"
disable_mask nfs-server.service

echo -e "\n[77] rpcbind controlado"
disable_mask rpcbind.service

echo -e "\n[78] rsync daemon controlado"
disable_mask rsyncd.service

echo -e "\n[79] Cliente NIS ausente"
remove_pkg ypbind

echo -e "\n[80] Cliente rsh ausente"
remove_pkg rsh

echo -e "\n[81] Cliente talk ausente"
remove_pkg talk

echo -e "\n[82] Cliente telnet ausente"
remove_pkg telnet

echo -e "\n[83] Cliente LDAP ausente"
remove_pkg openldap-clients

echo -e "\n[84] Serviços não essenciais mascarados"
for svc in avahi-daemon.service cups.service telnet.socket vsftpd.service nis.service tftp.service xinetd.service; do
    disable_mask "$svc"
done

echo -e "\n[85] TFTP server removido"
remove_pkg tftp-server

echo -e "\n[86] PolicyKit – quarentena de regras permissivas"

POLKIT_DIR="/etc/polkit-1/rules.d"
QUAR_DIR="/root/polkit_quarantine"

mkdir -p "$QUAR_DIR"

if ls "$POLKIT_DIR"/*.rules >/dev/null 2>&1; then
    for f in "$POLKIT_DIR"/*.rules; do
        [ -f "$f" ] || continue
        if grep -Eq 'polkit\.Result\.YES' "$f"; then
            backup "$f"
            mv "$f" "$QUAR_DIR/$(basename "$f").disabled_$(date +%Y%m%d_%H%M%S)"
            echo " Regra movida para quarentena: $f"
        fi
    done
else
    echo " Nenhuma regra customizada encontrada"
fi
