#!/usr/bin/env bash
echo "[79 - 103] Remediação genérica - Serviços e pacotes potencialmente perigosos"

# Lista de serviços a verificar
servicos=(
  dhcpd named dnsmasq smb vsftpd dovecot nfs-server ypserv cups rpcbind rsyncd snmpd
  telnet.socket tftp.socket squid httpd xinetd gdm
)

# Lista de pacotes a verificar
pacotes=(
  ftp openldap-clients ypbind telnet tftp
)

echo "Verificando serviços ativos ou habilitados..."
for svc in "${servicos[@]}"; do
  if systemctl is-enabled "$svc" &>/dev/null; then
    echo "⚠️ Serviço $svc está habilitado. Avalie se é realmente necessário e desabilite se não for."
  fi
done

echo -e "\nVerificando pacotes instalados..."
for pkg in "${pacotes[@]}"; do
  if rpm -q "$pkg" &>/dev/null; then
    echo "⚠️ Pacote $pkg está instalado. Avalie se deve ser removido."
  fi
done

echo -e "\n[97] Verificando se MTA está restrito ao loopback"
if grep -qv '^inet_interfaces = loopback-only' /etc/postfix/main.cf 2>/dev/null; then
  echo "⚠️ O MTA (Postfix) pode estar aceitando conexões externas. Configure 'inet_interfaces = loopback-only'."
fi

echo -e "\n[98] Verificação manual - Serviços escutando em rede externa:"
ss -tulnp | grep -v 127.0.0.1