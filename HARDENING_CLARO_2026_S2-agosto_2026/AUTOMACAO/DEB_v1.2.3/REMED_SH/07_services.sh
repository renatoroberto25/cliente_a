#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

disable_nonessential() { local id="$1" name="$2" u; echo "[$id] $name"; for u in avahi-daemon.service cups.service telnet.service vsftpd.service xinetd.service tftpd-hpa.service; do if systemctl list-unit-files "$u" --no-legend 2>/dev/null | grep -q .; then backup_unit "$u"; systemctl disable --now "$u" >/dev/null 2>&1 || true; fi; done; echo "OK: unidades nao essenciais tratadas"; }

purge_packages 51 'X11 removido' xserver-xorg-core
purge_packages 52 'Avahi desabilitado' avahi-daemon
purge_packages 53 'CUPS desabilitado' cups
purge_packages 54 'DHCP server ausente' isc-dhcp-server
purge_packages 55 'LDAP server ausente' slapd
purge_packages 56 'DNS server ausente' bind9
purge_packages 57 'FTP server ausente' vsftpd
purge_packages 58 'HTTP server ausente' apache2
purge_packages 59 'IMAP/POP3 removidos' dovecot-core cyrus-imapd
purge_packages 60 'Samba removido' samba
purge_packages 61 'Proxy HTTP removido' squid
purge_packages 62 'SNMP desabilitado' snmpd
purge_packages 63 'Servidor NIS removido' nis
purge_packages 64 'Servidor Telnet removido' telnetd
manual 65 'MTA local only' 'Configurar o MTA instalado para escutar somente no endereço local.'
purge_packages 66 'NFS server desabilitado' nfs-kernel-server
purge_packages 67 'rpcbind desabilitado' rpcbind
disable_unit 68 'rsync daemon desabilitado' rsync.service
purge_packages 69 'Cliente NIS removido' nis
purge_packages 70 'Cliente rsh removido' rsh-client
purge_packages 71 'Cliente talk removido' talk
purge_packages 72 'Cliente telnet removido' telnet
purge_packages 73 'Cliente LDAP removido' ldap-utils
disable_nonessential 74 'Serviços não essenciais habilitados'
purge_packages 75 'Servidor TFTP removido' tftpd-hpa
manual 76 'PolicyKit sem autorizações locais irrestritas' 'Revisar regras locais e remover somente concessões irrestritas não aprovadas.'
