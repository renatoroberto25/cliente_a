#!/usr/bin/env bash

echo -e "\n[61] X11 ausente"; 
(dpkg -l | grep -q '^ii\s\+xserver-xorg' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[62] Avahi ausente"; 
(dpkg -l | grep -q '^ii\s\+avahi-daemon' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[63] CUPS ausente"; 
(dpkg -l | grep -q '^ii\s\+cups' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[64] DHCP server ausente"; 
(dpkg -l | grep -q '^ii\s\+isc-dhcp-server' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[65] LDAP server ausente"; 
(dpkg -l | grep -q '^ii\s\+slapd' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[66] DNS server ausente"; 
(dpkg -l | grep -q '^ii\s\+bind9' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[67] FTP server ausente"; 
(dpkg -l | grep -q '^ii\s\+vsftpd' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[68] HTTP server ausente"; 
(dpkg -l | grep -q '^ii\s\+apache2' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[69] IMAP/POP3 server ausente"; 
(dpkg -l | grep -q '^ii\s\+dovecot-core' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[70] Samba ausente"; 
(dpkg -l | grep -q '^ii\s\+samba' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[71] Proxy HTTP ausente"; 
(dpkg -l | grep -q '^ii\s\+squid' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[72] SNMP ausente"; 
(dpkg -l | grep -q '^ii\s\+snmpd' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[73] NIS server ausente"; 
(dpkg -l | grep -q '^ii\s\+nis' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[74] Telnet server ausente"; 
(dpkg -l | grep -q '^ii\s\+telnetd' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[75] MTA em modo local-only"; 
([ ! -f /etc/postfix/main.cf ] || grep -Eq '^[[:space:]]*inet_interfaces[[:space:]]*=[[:space:]]*(localhost|loopback-only)\b' /etc/postfix/main.cf 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[76] NFS server controlado"; 
(systemctl is-enabled nfs-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[77] rpcbind controlado"; 
(systemctl is-enabled rpcbind &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[78] rsync daemon controlado"; 
(systemctl is-enabled rsync &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[79] Cliente NIS ausente"; 
(dpkg -l | grep -q '^ii\s\+ypbind' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[80] Cliente rsh ausente"; 
(dpkg -l | grep -q '^ii\s\+rsh-client' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[81] Cliente talk ausente"; 
(dpkg -l | grep -q '^ii\s\+talk' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[82] Cliente telnet ausente"; 
(dpkg -l | grep -q '^ii\s\+telnet' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[83] Cliente LDAP ausente"; 
(dpkg -l | grep -q '^ii\s\+ldap-utils' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[84] Serviços não essenciais removidos/mascarados"; 
(systemctl list-unit-files --state=enabled | grep -Eq 'avahi|cups|telnet|ftp|nis|tftp|xinetd' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[85] TFTP server removido"; 
(dpkg -l | grep -q '^ii\s\+tftpd-hpa' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE