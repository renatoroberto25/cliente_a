#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[61-74] Remediação – Remoção de serviços desnecessários (RHEL 7)"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

PKG_REMOVE() {
  if rpm -q "$1" &>/dev/null; then
    yum remove -y "$1" >/dev/null 2>&1
    echo " $1 removido"
  else
    echo " $1 não instalado"
  fi
}

disable_if_exists() {
  if systemctl list-unit-files 2>/dev/null | grep -q "^$1"; then
    systemctl stop "$1" >/dev/null 2>&1 || true
    systemctl disable "$1" >/dev/null 2>&1 || true
    systemctl mask "$1" >/dev/null 2>&1 || true
    echo " $1 desabilitado e mascarado"
  fi
}

echo -e "\n[61] X11"
PKG_REMOVE xorg-x11-server-common

echo -e "\n[62] Avahi"
PKG_REMOVE avahi
disable_if_exists avahi-daemon.service

echo -e "\n[63] CUPS"
PKG_REMOVE cups
disable_if_exists cups.service

echo -e "\n[64] DHCP server"
PKG_REMOVE dhcp-server

echo -e "\n[65] LDAP server"
PKG_REMOVE openldap-servers

echo -e "\n[66] DNS server (BIND)"
PKG_REMOVE bind
disable_if_exists named.service

echo -e "\n[67] FTP server"
PKG_REMOVE vsftpd
disable_if_exists vsftpd.service

echo -e "\n[68] HTTP server"
PKG_REMOVE httpd
disable_if_exists httpd.service

echo -e "\n[69] IMAP/POP3 server"
PKG_REMOVE dovecot
disable_if_exists dovecot.service

echo -e "\n[70] Samba"
PKG_REMOVE samba
disable_if_exists smb.service
disable_if_exists nmb.service

echo -e "\n[71] Proxy HTTP"
PKG_REMOVE squid
disable_if_exists squid.service

echo -e "\n[72] SNMP"
PKG_REMOVE net-snmp
disable_if_exists snmpd.service

echo -e "\n[73] NIS server"
PKG_REMOVE ypserv
disable_if_exists ypserv.service

echo -e "\n[74] Telnet server"
PKG_REMOVE telnet-server
disable_if_exists telnet.socket

echo -e "\n[61-74] Concluído"
