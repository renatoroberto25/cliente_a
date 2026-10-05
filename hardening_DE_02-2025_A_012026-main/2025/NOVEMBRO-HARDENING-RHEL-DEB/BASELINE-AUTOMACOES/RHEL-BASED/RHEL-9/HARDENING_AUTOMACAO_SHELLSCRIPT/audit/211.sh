#!/usr/bin/env bash

# Lista de serviços para verificar (conforme os tópicos do CIS)
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

# Função para verificar se um serviço está ativo e habilitado
verificar_servico() {
    local servico="$1"

    # Verifica se o serviço existe no systemd antes de tentar consultá-lo
    if systemctl list-unit-files --type=service --no-pager | grep -q "^$servico"; then
        # Verifica se o serviço está rodando
        if systemctl list-units --type=service --no-pager | grep -q "^$servico"; then
echo "⚠️[REPROVADO]: Serviço $servico está ATIVO. Por favor, desative-o."
        else
echo "✅ [APROVADO]: Serviço $servico não está ativo."
        fi

        # Verifica se o serviço está habilitado
        if systemctl is-enabled --quiet "$servico"; then
echo "⚠️[REPROVADO]: Serviço $servico está HABILITADO. Por favor, desative-o."
        else
echo "✅ [APROVADO]: Serviço $servico não está habilitado."
        fi
    else
echo "✅ [APROVADO]: Serviço $servico não está instalado."
    fi
}

# Verificar cada serviço da lista
for servico in "${servicos[@]}"; do
    verificar_servico "$servico"
done

# Verificar configuração do agente de transferência de e-mail (Postfix)
mta_configurado_para_local() {
    if systemctl is-active --quiet postfix && [ -f /etc/postfix/main.cf ]; then
        if grep -Eiq "^\s*inet_interfaces\s*=\s*(loopback-only|localhost|127\.0\.0\.1)" /etc/postfix/main.cf; then
echo "✅ [APROVADO]: Postfix está configurado para modo local."
        else
echo "⚠️[REPROVADO]: Postfix não está configurado para modo local. Ajuste 'inet_interfaces' para 'loopback-only' ou 'localhost'."
        fi
    else
echo "✅ [APROVADO]: Postfix não está instalado ou não está rodando."
    fi
}

mta_configurado_para_local

# Verificar configuração do agente de transferência de e-mail (Sendmail)
sendmail_configurado_para_local() {
    if systemctl is-active --quiet sendmail && [ -f /etc/mail/sendmail.cf ]; then
        if grep -Eiq "^\s*O?\s*DaemonPortOptions=.*(Addr=127\.0\.0\.1|localhost)" /etc/mail/sendmail.cf; then
echo "✅ [APROVADO]: Sendmail está configurado para modo local."
        else
echo "⚠️[REPROVADO]: Sendmail não está configurado para modo local. Ajuste 'DaemonPortOptions' para 'Addr=127.0.0.1'."
        fi
    else
echo "✅ [APROVADO]: Sendmail não está instalado ou não está rodando."
    fi
}

sendmail_configurado_para_local

# Verificar serviços escutando em portas abertas
verificar_servicos_escutando() {
echo "Verificando serviços escutando em portas abertas..."

    # Usa 'ss' se disponível, senão usa 'netstat'
    if command -v ss &>/dev/null; then
        ss -plntu | awk 'NR>1 {print}'

    elif command -v netstat &>/dev/null; then
        netstat -tulnp | awk 'NR>2 {print}'

    else
echo "⚠️ ERRO: Nenhuma ferramenta encontrada para listar portas abertas (ss ou netstat)."
    fi

echo "\nSe um serviço listado não for necessário:"
echo "- Remova o pacote correspondente."
echo "- Se for necessário como dependência, pare e masque o serviço e/ou socket."
}

verificar_servicos_escutando
