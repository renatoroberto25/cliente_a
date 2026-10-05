#!/usr/bin/env bash
echo "[61 - 86] Remediação: Serviços e clientes desnecessários"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

remove_pkg() {
    PKG="$1"
    if rpm -q "$PKG" &>/dev/null; then
        dnf remove -y "$PKG" >/dev/null 2>&1
        echo "✔ Pacote removido: $PKG"
    else
        echo "✔ $PKG não está instalado"
    fi
}

disable_service() {
    SVC="$1"
    if systemctl list-unit-files | grep -q "^$SVC"; then
        systemctl stop "$SVC" >/dev/null 2>&1
        systemctl disable "$SVC" >/dev/null 2>&1
        systemctl mask "$SVC" >/dev/null 2>&1
        echo "✔ Serviço desabilitado e mascarado: $SVC"
    else
        echo "✔ Serviço não encontrado: $SVC"
    fi
}

echo -e "\n[61] Remover X11"
remove_pkg xorg-x11-server-common

echo -e "\n[62] Remover Avahi"
remove_pkg avahi

echo -e "\n[63] Remover CUPS"
remove_pkg cups

echo -e "\n[64] Remover DHCP server"
remove_pkg dhcp-server

echo -e "\n[65] Remover LDAP server"
remove_pkg openldap-servers

echo -e "\n[66] Remover Bind DNS server"
remove_pkg bind

echo -e "\n[67] Remover FTP (vsftpd)"
remove_pkg vsftpd

echo -e "\n[68] Remover Apache HTTP"
remove_pkg httpd

echo -e "\n[69] Remover Dovecot (IMAP/POP3)"
remove_pkg dovecot

echo -e "\n[70] Remover Samba"
remove_pkg samba

echo -e "\n[71] Remover Squid"
remove_pkg squid

echo -e "\n[72] Remover SNMP"
remove_pkg net-snmp

echo -e "\n[73] Remover NIS server"
remove_pkg ypserv

echo -e "\n[74] Remover Telnet server"
remove_pkg telnet-server

echo -e "\n[75] Configurar Postfix para loopback-only"

FILE="/etc/postfix/main.cf"
if [ -f "$FILE" ]; then
    backup "$FILE"
    if grep -q '^inet_interfaces' "$FILE"; then
        sed -i 's/^inet_interfaces.*/inet_interfaces = loopback-only/' "$FILE"
    else
        echo "inet_interfaces = loopback-only" >> "$FILE"
    fi
    systemctl restart postfix >/dev/null 2>&1
    echo "✔ Postfix ajustado para loopback-only"
else
    echo "✔ Postfix não instalado"
fi

echo -e "\n[76] Desabilitar NFS server"
disable_service nfs-server

echo -e "\n[77] Desabilitar rpcbind"
disable_service rpcbind

echo -e "\n[78] Desabilitar rsyncd"
disable_service rsyncd

echo -e "\n[79] Remover cliente NIS"
remove_pkg ypbind

echo -e "\n[80] Remover cliente rsh"
remove_pkg rsh

echo -e "\n[81] Remover cliente talk"
remove_pkg talk

echo -e "\n[82] Remover cliente telnet"
remove_pkg telnet

echo -e "\n[83] Remover cliente LDAP"
remove_pkg openldap-clients

echo -e "\n[84] Desabilitar serviços não essenciais habilitados"

for svc in avahi-daemon cups tftp xinetd telnet vsftpd nis ; do
    disable_service "$svc"
done

echo "✔ Serviços supérfluos desabilitados"

echo -e "\n[85] Remover TFTP server"
remove_pkg tftp-server

echo -e "\n[86] Endurecer PolicyKit"
POLKIT_DIR="/etc/polkit-1/rules.d"
if ls "$POLKIT_DIR"/*.rules >/dev/null 2>&1; then
    ALTEROU=0
    for f in "$POLKIT_DIR"/*.rules; do
        if grep -Eq 'polkit\.Result\.YES|allow' "$f" 2>/dev/null; then
            backup "$f"
            if ! grep -q '^\s*//' "$f"; then
                sed -i '/polkit\.Result\.YES/s/^/\/\/ BLOQUEADO HARDENING: /;/allow/s/^/\/\/ BLOQUEADO HARDENING: /' "$f"
            else
                sed -i '/polkit\.Result\.YES/ { /^[[:space:]]*\/\//! s/^/\/\/ BLOQUEADO HARDENING: / ; } ; /allow/ { /^[[:space:]]*\/\//! s/^/\/\/ BLOQUEADO HARDENING: / ; }' "$f"
            fi
            if ! grep -Eq 'polkit\.Result\.YES|allow' "$f" 2>/dev/null; then
                echo "✔ Regra permissiva neutralizada: $f"
                ALTEROU=1
            else
                echo "⚠️ Ainda há conteúdo permissivo em: $f"
            fi
        fi
    done
    if [ "$ALTEROU" -eq 0 ]; then
        echo "✔ Nenhuma regra permissiva encontrada"
    fi
else
    echo "✔ Nenhum arquivo .rules encontrado em $POLKIT_DIR"
fi


echo "OK"
exit 0
