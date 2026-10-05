#!/usr/bin/env bash
echo "[61 - 86] Remediação: Serviços e clientes desnecessários"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

remove_pkg() {
    PKG="$1"
    SVC="$2"
    PORTS="$3"

    if ! rpm -q "$PKG" &>/dev/null; then
        echo "✔ $PKG não está instalado"
        return 0
    fi

    if [ -n "$SVC" ] && systemctl is-active --quiet "$SVC"; then
        echo "⚠ $PKG não removido: serviço $SVC ativo"
        return 1
    fi

    if [ -n "$PORTS" ]; then
        for P in $PORTS; do
            ss -tuln | awk '{print $5}' | grep -q ":$P$" && {
                echo "⚠ $PKG não removido: porta $P em uso"
                return 1
            }
        done
    fi

    dnf remove -y "$PKG" >/dev/null 2>&1
    echo "✔ Pacote removido: $PKG"
}

disable_service() {
    SVC="$1"
    if systemctl list-unit-files | grep -q "^$SVC"; then
        systemctl stop "$SVC" >/dev/null 2>&1
        systemctl disable "$SVC" >/dev/null 2>&1
        systemctl mask "$SVC" >/dev/null 2>&1
        echo "✔ Serviço desabilitado: $SVC"
    else
        echo "✔ Serviço não encontrado: $SVC"
    fi
}

echo -e "\n[61] X11"
remove_pkg xorg-x11-server-common

echo -e "\n[62] Avahi"
remove_pkg avahi

echo -e "\n[63] CUPS"
remove_pkg cups

echo -e "\n[64] DHCP Server"
remove_pkg dhcp-server dhcpd "67 68"

echo -e "\n[65] LDAP Server"
remove_pkg openldap-servers slapd "389 636"

echo -e "\n[66] Bind DNS"
remove_pkg bind named "53"

echo -e "\n[67] FTP"
remove_pkg vsftpd vsftpd "21"

echo -e "\n[68] Apache HTTP"
remove_pkg httpd httpd "80 443"

echo -e "\n[69] Dovecot"
remove_pkg dovecot dovecot "110 143 993"

echo -e "\n[70] Samba"
remove_pkg samba smb "139 445"

echo -e "\n[71] Squid"
remove_pkg squid squid "3128 3130"

echo -e "\n[72] SNMP"
remove_pkg net-snmp snmpd "161 162"

echo -e "\n[73] NIS Server"
remove_pkg ypserv ypserv "111 744"

echo -e "\n[74] Telnet Server"
remove_pkg telnet-server

echo -e "\n[75] Postfix loopback-only"
FILE="/etc/postfix/main.cf"
if [ -f "$FILE" ]; then
    backup "$FILE"
    grep -q '^inet_interfaces' "$FILE" \
        && sed -i 's/^inet_interfaces.*/inet_interfaces = loopback-only/' "$FILE" \
        || echo "inet_interfaces = loopback-only" >> "$FILE"
    systemctl restart postfix >/dev/null 2>&1
    echo "✔ Postfix ajustado"
else
    echo "✔ Postfix não instalado"
fi

echo -e "\n[76] NFS Server"
disable_service nfs-server

echo -e "\n[77] rpcbind"
disable_service rpcbind

echo -e "\n[78] rsyncd"
disable_service rsyncd

echo -e "\n[79] Cliente NIS"
remove_pkg ypbind

echo -e "\n[80] Cliente rsh"
remove_pkg rsh

echo -e "\n[81] Cliente talk"
remove_pkg talk

echo -e "\n[82] Cliente telnet"
remove_pkg telnet

echo -e "\n[83] Cliente LDAP"
remove_pkg openldap-clients

echo -e "\n[84] Serviços habilitados desnecessários"
for svc in avahi-daemon cups tftp xinetd telnet vsftpd nis; do
    disable_service "$svc"
done

echo -e "\n[85] TFTP Server"
remove_pkg tftp-server tftp "69"

echo -e "\n[86] PolicyKit"
POLKIT_DIR="/etc/polkit-1/rules.d"
for f in "$POLKIT_DIR"/*.rules 2>/dev/null; do
    grep -Eq 'polkit.Result.YES|allow' "$f" || continue
    backup "$f"
    sed -i '/polkit.Result.YES/d;/allow/d' "$f"
    echo "✔ Regra ajustada: $f"
done
echo "✔ PolicyKit verificado"
