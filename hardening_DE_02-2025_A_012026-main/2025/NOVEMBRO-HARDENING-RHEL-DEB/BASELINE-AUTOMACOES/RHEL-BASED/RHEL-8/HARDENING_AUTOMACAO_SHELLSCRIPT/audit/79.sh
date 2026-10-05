#!/usr/bin/env bash
echo "[79 - 103] Auditoria de serviços e pacotes não recomendados"

# Função padrão para checar serviço
check_service_disabled() {
  local svc="$1"
  local id="$2"
  echo "[$id] Verificando se o serviço $svc está desabilitado"
  systemctl is-enabled "$svc" &>/dev/null && echo "⚠️ REPROVADO - $svc habilitado" || echo "✅ APROVADO - $svc desabilitado ou ausente"
}

# Função para verificar pacote
check_package_absent() {
  local pkg="$1"
  local id="$2"
  echo "[$id] Verificando se o pacote $pkg está ausente"
  rpm -q "$pkg" &>/dev/null && echo "⚠️ REPROVADO - $pkg instalado" || echo "✅ APROVADO - $pkg não instalado"
}

# Serviços
check_service_disabled dhcpd              79
check_service_disabled named              80
check_service_disabled dnsmasq            81
check_service_disabled smb                82
check_service_disabled vsftpd             83
check_service_disabled dovecot            84
check_service_disabled nfs-server         85
check_service_disabled ypserv             86
check_service_disabled cups               87
check_service_disabled rpcbind            88
check_service_disabled rsyncd             89
check_service_disabled snmpd              90
check_service_disabled telnet.socket      91
check_service_disabled tftp.socket        92
check_service_disabled squid              93
check_service_disabled httpd              94
check_service_disabled xinetd             95
check_service_disabled gdm                96

echo "[97] Verificando configuração de MTA para uso local"
grep -q '^inet_interfaces = loopback-only' /etc/postfix/main.cf && echo "✅ APROVADO - MTA restrito à interface local" || echo "⚠️ REPROVADO - MTA pode estar exposto"

echo "[98] Verificação manual - Serviços escutando em interfaces externas"
ss -tulnp | grep -v 127.0.0.1
echo "⚠️ [98] Avaliação manual necessária: confira se apenas serviços aprovados estão escutando externamente."

# Pacotes não recomendados
check_package_absent ftp               99
check_package_absent openldap-clients 100
check_package_absent ypbind           101
check_package_absent telnet           102
check_package_absent tftp             103