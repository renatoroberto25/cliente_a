#!/usr/bin/env bash

echo -e "\n[61] X11 ausente"
(rpm -q xorg-x11-server-common &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[62] Avahi ausente"
(rpm -q avahi &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[63] CUPS ausente"
(rpm -q cups &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[64] DHCP server ausente"
(rpm -q dhcp-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[65] LDAP server ausente"
(rpm -q openldap-servers &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[66] DNS server ausente"
(rpm -q bind &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[67] FTP server ausente"
(rpm -q vsftpd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[68] HTTP server ausente"
(rpm -q httpd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[69] IMAP/POP3 server ausente"
(rpm -q dovecot &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[70] Samba ausente"
(rpm -q samba &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[71] Proxy HTTP ausente"
(rpm -q squid &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[72] SNMP ausente"
(rpm -q net-snmp &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[73] NIS server ausente"
(rpm -q ypserv &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[74] Telnet server ausente"
(rpm -q telnet-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[75] MTA em modo local-only"
( [ ! -f /etc/postfix/main.cf ] || grep -Eq '^[[:space:]]*inet_interfaces[[:space:]]*=[[:space:]]*(localhost|loopback-only)\b' /etc/postfix/main.cf 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[76] NFS server controlado"
(systemctl is-enabled nfs-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[77] rpcbind controlado"
(systemctl is-enabled rpcbind &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[78] rsync daemon controlado"
(systemctl is-enabled rsyncd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[79] Cliente NIS ausente"
(rpm -q ypbind &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[80] Cliente rsh ausente"
(rpm -q rsh &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[81] Cliente talk ausente"
(rpm -q talk &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[82] Cliente telnet ausente"
(rpm -q telnet &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[83] Cliente LDAP ausente"
(rpm -q openldap-clients &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[84] Serviços não essenciais removidos/mascarados"
(systemctl list-unit-files --state=enabled | grep -Eq 'avahi|cups|telnet|ftp|nis|tftp|xinetd' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[85] TFTP server removido"
(rpm -q tftp-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo "[86] PolicyKit endurecido"
( grep -Eq 'polkit.Result.YES|allow' /etc/polkit-1/rules.d/*.rules 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO" )


