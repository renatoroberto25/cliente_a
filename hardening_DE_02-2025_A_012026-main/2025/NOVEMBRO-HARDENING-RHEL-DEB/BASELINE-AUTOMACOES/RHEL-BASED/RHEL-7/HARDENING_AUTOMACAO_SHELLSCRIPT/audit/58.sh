#!/usr/bin/env bash
# [58–79] Auditoria HITSS - Serviços e pacotes (Servidores baseados em RHEL 7)
set -euo pipefail

echo -e "\n[58] Verifique se o xinetd não está instalado"
rpm -q xinetd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[59] Verifique se a sincronização de tempo está em uso"
(systemctl is-active chronyd ntpd &>/dev/null || pgrep -x chronyd ntpd &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[60] Verifique se o chrony está configurado"
[ -s /etc/chrony.conf ] && grep -Eq '^(server|pool)\s' /etc/chrony.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[61] Verifique se o ntp está configurado"
[ -s /etc/ntp.conf ] && grep -Eq '^(server|pool)\s' /etc/ntp.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[62] Verifique se o X11 Server não está instalado"
rpm -qa | grep -Eq 'xorg-x11-server' && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[63] Verifique se o Avahi Server não está instalado"
rpm -q avahi-daemon &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[64] Verifique se o CUPS não está instalado"
rpm -q cups &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[65] Verifique se o DHCP Server não está instalado"
rpm -q dhcp &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[66] Verifique se o LDAP Server não está instalado"
rpm -q openldap-servers &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[67] Verifique se o DNS Server não está instalado"
rpm -q bind &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[68] Verifique se o FTP Server não está instalado"
rpm -q vsftpd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[69] Verifique se o HTTP Server não está instalado"
rpm -q httpd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[70] Verifique se o IMAP/POP3 Server não está instalado"
rpm -q dovecot &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[71] Verifique se o Samba não está instalado"
rpm -q samba &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[72] Verifique se o Proxy HTTP não está instalado"
rpm -q squid &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[73] Verifique se o SNMP não está instalado"
rpm -q net-snmp &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[74] Verifique se o NIS Server não está instalado"
rpm -q ypserv &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[75] Verifique se o Telnet Server não está instalado"
rpm -q telnet-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[76] Verifique se o MTA está restrito à interface local"
grep -q '^inet_interfaces\s*=\s*loopback-only' /etc/postfix/main.cf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[77] Verifique se o NFS Server não está instalado ou está mascarado"
(rpm -q nfs-utils &>/dev/null && systemctl is-enabled nfs-server &>/dev/null) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[78] Verifique se o rpcbind não está instalado ou está mascarado"
(rpm -q rpcbind &>/dev/null && systemctl is-enabled rpcbind &>/dev/null) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[79] Verifique se o rsync não está instalado ou está mascarado"
(rpm -q rsync &>/dev/null && systemctl is-enabled rsyncd &>/dev/null) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"