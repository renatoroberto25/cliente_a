#!/bin/bash
set -e

echo "[BLOCO 1] Aplicando falhas baseadas em serviços inseguros..."

# Função simples idempotente
install_enable() {
    local pkg="$1"
    local svc="$2"
    if ! rpm -q "$pkg" &>/dev/null; then
        yum install -y "$pkg" || true
    fi
    if [ -n "$svc" ]; then
        systemctl enable "$svc" --now 2>/dev/null || true
    fi
}

# Lista de pacotes inseguros (cada um gera múltiplas reprovações)
install_enable "xorg-x11-server-common" ""         # X11 proibido
install_enable "cups" "cups"                      # Impressão
install_enable "vsftpd" "vsftpd"                  # FTP
install_enable "telnet-server" "telnet.socket"    # Telnet
install_enable "tftp-server" "tftp.socket"        # TFTP
install_enable "samba" "smb"                      # SMB
install_enable "bind" "named"                     # DNS server
install_enable "dovecot" "dovecot"                # IMAP/POP3
install_enable "openldap-servers" "slapd"         # LDAP server
install_enable "squid" "squid"                    # Proxy
install_enable "net-snmp" "snmpd"                 # SNMP
install_enable "ypserv" "ypserv"                  # NIS server
install_enable "rsync" "rsyncd"                   # rsync daemon
install_enable "nfs-utils" "nfs-server"           # NFS server
install_enable "rpcbind" "rpcbind"                # RPCBind

echo "[BLOCO 1] Finalizado com sucesso (serviços inseguros instalados e habilitados)."
