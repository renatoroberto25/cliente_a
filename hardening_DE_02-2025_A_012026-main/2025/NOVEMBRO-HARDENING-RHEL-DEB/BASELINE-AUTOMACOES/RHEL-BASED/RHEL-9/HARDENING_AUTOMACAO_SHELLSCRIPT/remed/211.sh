#!/usr/bin/env bash

# Lista de serviços a serem desativados e mascarados
servicos=(
    autofs
    avahi-daemon
    dhcpd
    named
    dnsmasq
    smb
    vsftpd
    dovecot
    nfs-server
    ypserv
    cups
    rpcbind
    rsyncd
    snmpd
    telnet.socket
    tftp.socket
    squid
    httpd
    xinetd
    xorg
)
log() {
    echo "[✅ SUCESSO] $1"
}

err() {
    echo "[⚠️ FALHA] $1"
}
# Função para desativar e mascarar serviços inseguros
desativar_servico() {
    local servico="$1"

    # Verifica se o serviço existe antes de tentar desativá-lo
    if systemctl list-unit-files --type=service --no-pager | grep -q "^$servico"; then
        echo "Desativando e mascarando $servico..."

        # Para o serviço se estiver rodando
        if systemctl is-active --quiet "$servico"; then
            systemctl stop "$servico" 2>/dev/null
        fi

        # Desabilita e mascara o serviço
        systemctl disable "$servico" 2>/dev/null
        systemctl mask "$servico" 2>/dev/null

        log " Serviço $servico desativado com sucesso."
    else
        err " Serviço $servico não encontrado ou não gerenciável pelo systemctl."
    fi
}

# Aplicar a desativação em todos os serviços da lista
for servico in "${servicos[@]}"; do
    desativar_servico "$servico"
done

# Função para configurar Postfix
configurar_postfix() {
    if systemctl is-active --quiet postfix && [ -f /etc/postfix/main.cf ]; then
        echo "Configurando Postfix para modo local..."
        sed -i 's/^inet_interfaces.*/inet_interfaces = loopback-only/' /etc/postfix/main.cf
        systemctl restart postfix
        echo "✅ Postfix configurado para modo local."
    else
        echo "⚠️ Postfix não encontrado ou não está rodando, pulando configuração."
    fi
}

configurar_postfix

# Função para configurar Sendmail
configurar_sendmail() {
    if systemctl is-active --quiet sendmail && [ -f /etc/mail/sendmail.cf ]; then
        echo "Configurando Sendmail para modo local..."
        sed -i '/^O DaemonPortOptions=/c\O DaemonPortOptions=Port=smtp,Addr=127.0.0.1, Name=MTA' /etc/mail/sendmail.cf
        systemctl restart sendmail
        echo "✅ Sendmail configurado para modo local."
    else
        echo "⚠️ Sendmail não encontrado ou não está rodando, pulando configuração."
    fi
}

configurar_sendmail
