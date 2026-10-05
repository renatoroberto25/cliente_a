#!/usr/bin/env bash

{
    # Remediação: 65 Garantir que o acesso a /etc/motd esteja configurado corretamente
    if [ -f /etc/motd ]; then
        sudo rm -f /etc/motd
        echo " - Conteúdo de /etc/motd removido."
    fi

    if [ -d /etc/motd.d ]; then
        sudo rm -rf /etc/motd.d/*
        echo " - Conteúdo de /etc/motd.d/* removido."
    fi

    # Remediação: 63 Garantir que o banner de aviso de login local esteja configurado corretamente
    echo "Apenas usuários autorizados. Toda atividade pode ser monitorada e reportada." | sudo tee /etc/issue > /dev/null
    if [ -f /etc/issue ]; then
        sudo chown root:root /etc/issue
        sudo chmod 644 /etc/issue
        echo " - /etc/issue configurado."
    fi

    # Remediação: 64 Garantir que o banner de aviso de login remoto esteja configurado corretamente
    echo "Apenas usuários autorizados. Toda atividade pode ser monitorada e reportada." | sudo tee /etc/issue.net > /dev/null
    if [ -f /etc/issue.net ]; then
        sudo chown root:root /etc/issue.net
        sudo chmod 644 /etc/issue.net
        echo " - /etc/issue.net configurado."
    fi

    # Remediação: 65 Garantir que o acesso a /etc/motd esteja configurado corretamente - criar conteúdo seguro
    SECURE_MOTD="Bem-vindo ao sistema!

Este sistema é para uso autorizado apenas.

Por favor, siga as políticas de segurança da sua organização.

Para suporte, entre em contato com [endereço de e-mail ou número de telefone].

Data e Hora do Sistema: $(date +\"%Y-%m-%d %H:%M:%S %Z\")"

    echo -e "$SECURE_MOTD" | sudo tee /etc/motd > /dev/null
    if [ -f /etc/motd ]; then
        sudo chown root:root /etc/motd
        sudo chmod 644 /etc/motd
        echo " - /etc/motd criado com conteúdo seguro e permissões corretas."
    fi
}