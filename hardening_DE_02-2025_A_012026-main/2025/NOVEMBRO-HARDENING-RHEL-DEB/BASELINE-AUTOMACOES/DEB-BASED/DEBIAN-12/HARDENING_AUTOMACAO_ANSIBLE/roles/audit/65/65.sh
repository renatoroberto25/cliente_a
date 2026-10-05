#!/usr/bin/env bash

echo -e "\n[65] Verifique se o serviço autofs não está em uso"
(systemctl is-enabled autofs 2>/dev/null | grep -q '^enabled$' || ! dpkg -s autofs >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[66] Verifique se o serviço avahi-daemon não está em uso"
(systemctl is-enabled avahi-daemon 2>/dev/null | grep -q '^enabled$' || ! dpkg -s avahi-daemon >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[67] Verifique se o serviço dhcp-server não está em uso"
(systemctl is-enabled isc-dhcp-server 2>/dev/null | grep -q '^enabled$' || ! dpkg -s isc-dhcp-server >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[68] Verifique se o serviço bind9 (DNS server) não está em uso"
(systemctl is-enabled bind9 2>/dev/null | grep -q '^enabled$' || ! dpkg -s bind9 >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[69] Verifique se o serviço dnsmasq não está em uso"
(systemctl is-enabled dnsmasq 2>/dev/null | grep -q '^enabled$' || ! dpkg -s dnsmasq >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[70] Verifique se o serviço ftp-server (vsftpd) não está em uso"
(systemctl is-enabled vsftpd 2>/dev/null | grep -q '^enabled$' || ! dpkg -s vsftpd >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[71] Verifique se o serviço ldap-server (slapd) não está em uso"
(systemctl is-enabled slapd 2>/dev/null | grep -q '^enabled$' || ! dpkg -s slapd >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[72] Verifique se o serviço de mensagens (dovecot) não está em uso"
(systemctl is-enabled dovecot 2>/dev/null | grep -q '^enabled$' || ! dpkg -s dovecot-core >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[73] Verifique se o serviço NFS server não está em uso"
(systemctl is-enabled nfs-server 2>/dev/null | grep -q '^enabled$' || ! dpkg -s nfs-kernel-server >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[74] Verifique se o serviço NIS server não está em uso"
(systemctl is-enabled nis 2>/dev/null | grep -q '^enabled$' || ! dpkg -s nis >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[75] Verifique se o serviço de impressão (cups) não está em uso"
(systemctl is-enabled cups 2>/dev/null | grep -q '^enabled$' || ! dpkg -s cups >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[76] Verifique se o serviço rpcbind não está em uso"
(systemctl is-enabled rpcbind 2>/dev/null | grep -q '^enabled$' || ! dpkg -s rpcbind >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[77] Verifique se o serviço rsync não está em uso"
(systemctl is-enabled rsync 2>/dev/null | grep -q '^enabled$') && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[78] Verifique se o serviço samba não está em uso"
(systemctl is-enabled smbd 2>/dev/null | grep -q '^enabled$' || ! dpkg -s samba >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[79] Verifique se o serviço SNMP não está em uso"
(systemctl is-enabled snmpd 2>/dev/null | grep -q '^enabled$' || ! dpkg -s snmpd >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[80] Verifique se o serviço TFTP não está em uso"
(systemctl is-enabled tftpd-hpa 2>/dev/null | grep -q '^enabled$' || ! dpkg -s tftpd-hpa >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[81] Verifique se o serviço de proxy (squid) não está em uso"
(systemctl is-enabled squid 2>/dev/null | grep -q '^enabled$' || ! dpkg -s squid >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[82] Verifique se o serviço web (apache/nginx) não está em uso"
(systemctl is-enabled apache2 2>/dev/null | grep -q '^enabled$' || systemctl is-enabled nginx 2>/dev/null | grep -q '^enabled$') && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[83] Verifique se o serviço xinetd não está em uso"
(systemctl is-enabled xinetd 2>/dev/null | grep -q '^enabled$' || ! dpkg -s xinetd >/dev/null 2>&1) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[84] Verifique se o servidor gráfico (Xorg) não está em uso"
pgrep -x Xorg >/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[85] Verifique se o MTA está configurado apenas para localhost"
if [ -f /etc/postfix/main.cf ]; then
    grep -q '^inet_interfaces = loopback-only' /etc/postfix/main.cf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
else
    echo "✅ APROVADO - Postfix não está instalado"
fi