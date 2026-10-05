#!/usr/bin/env bash
# [58–79] Remediação HITSS - Remover pacotes e serviços de rede (Servidores baseados em RHEL 7)
# Remove apenas se instalado; nenhuma ação se ausente.
set -euo pipefail

echo -e "\n[58] Remover xinetd se instalado"
rpm -q xinetd &>/dev/null && yum remove -y xinetd || echo "✅ Já ausente"

echo -e "\n[59] Sincronização de tempo - manual (chrony/ntp conforme política local)"
echo "⚠️ Verificar manualmente se chrony ou ntpd estão configurados conforme o padrão da empresa."

echo -e "\n[60] Remover chrony (se política exigir outro serviço)"
rpm -q chrony &>/dev/null && yum remove -y chrony || echo "✅ Já ausente"

echo -e "\n[61] Remover ntp (se política exigir outro serviço)"
rpm -q ntp &>/dev/null && yum remove -y ntp || echo "✅ Já ausente"

echo -e "\n[62] Remover X11 Server"
rpm -qa | grep -Eq 'xorg-x11-server' && yum remove -y xorg-x11-server* || echo "✅ Já ausente"

echo -e "\n[63] Remover Avahi Server"
rpm -q avahi-daemon &>/dev/null && yum remove -y avahi-daemon || echo "✅ Já ausente"

echo -e "\n[64] Remover CUPS"
rpm -q cups &>/dev/null && yum remove -y cups || echo "✅ Já ausente"

echo -e "\n[65] Remover DHCP Server"
rpm -q dhcp &>/dev/null && yum remove -y dhcp || echo "✅ Já ausente"

echo -e "\n[66] Remover LDAP Server"
rpm -q openldap-servers &>/dev/null && yum remove -y openldap-servers || echo "✅ Já ausente"

echo -e "\n[67] Remover DNS Server (bind)"
rpm -q bind &>/dev/null && yum remove -y bind || echo "✅ Já ausente"

echo -e "\n[68] Remover FTP Server"
rpm -q vsftpd &>/dev/null && yum remove -y vsftpd || echo "✅ Já ausente"

echo -e "\n[69] Remover HTTP Server"
rpm -q httpd &>/dev/null && yum remove -y httpd || echo "✅ Já ausente"

echo -e "\n[70] Remover IMAP/POP3 Server"
rpm -q dovecot &>/dev/null && yum remove -y dovecot || echo "✅ Já ausente"

echo -e "\n[71] Remover Samba"
rpm -q samba &>/dev/null && yum remove -y samba || echo "✅ Já ausente"

echo -e "\n[72] Remover HTTP Proxy Server"
rpm -q squid &>/dev/null && yum remove -y squid || echo "✅ Já ausente"

echo -e "\n[73] Remover SNMP Server"
rpm -q net-snmp &>/dev/null && yum remove -y net-snmp || echo "✅ Já ausente"

echo -e "\n[74] Remover NIS Server"
rpm -q ypserv &>/dev/null && yum remove -y ypserv || echo "✅ Já ausente"

echo -e "\n[75] Remover Telnet Server"
rpm -q telnet-server &>/dev/null && yum remove -y telnet-server || echo "✅ Já ausente"

echo -e "\n[76] Ajustar MTA para uso local"
if [ -f /etc/postfix/main.cf ]; then
  cp -a /etc/postfix/main.cf /etc/postfix/main.cf.bak.$(date +%F_%H%M%S)
  sed -i 's/^inet_interfaces.*/inet_interfaces = loopback-only/' /etc/postfix/main.cf
  echo "✅ MTA ajustado para loopback-only"
else
  echo "⚠️ Postfix não encontrado"
fi

echo -e "\n[77] Remover NFS Utils"
rpm -q nfs-utils &>/dev/null && yum remove -y nfs-utils || echo "✅ Já ausente"

echo -e "\n[78] Remover rpcbind"
rpm -q rpcbind &>/dev/null && yum remove -y rpcbind || echo "✅ Já ausente"

echo -e "\n[79] Remover rsync"
rpm -q rsync &>/dev/null && yum remove -y rsync || echo "✅ Já ausente"