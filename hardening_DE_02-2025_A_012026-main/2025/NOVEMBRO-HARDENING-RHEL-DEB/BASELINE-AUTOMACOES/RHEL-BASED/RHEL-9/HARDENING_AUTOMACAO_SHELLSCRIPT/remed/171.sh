#!/usr/bin/env bash

{
    echo "[63-65] Remediação de banners e mensagens do sistema"

    # 63 - Garantir que o banner de aviso de login local esteja configurado corretamente
    if [ -f /etc/issue ]; then
        sudo chown root:root /etc/issue
        sudo chmod 644 /etc/issue
        echo " - /etc/issue permissões e propriedade ajustadas."
    else
        echo " - /etc/issue não encontrado (configuração de conteúdo é responsabilidade da organização)."
    fi

    # 64 - Garantir que o banner de aviso de login remoto esteja configurado corretamente
    if [ -f /etc/issue.net ]; then
        sudo chown root:root /etc/issue.net
        sudo chmod 644 /etc/issue.net
        echo " - /etc/issue.net permissões e propriedade ajustadas."
    else
        echo " - /etc/issue.net não encontrado (configuração de conteúdo é responsabilidade da organização)."
    fi

    # 65 - Garantir que o acesso a /etc/motd esteja configurado corretamente
    if [ -f /etc/motd ]; then
        sudo chown root:root /etc/motd
        sudo chmod 644 /etc/motd
        echo " - /etc/motd permissões e propriedade ajustadas."
    else
        echo " - /etc/motd não encontrado (configuração de conteúdo é responsabilidade da organização)."
    fi
}
