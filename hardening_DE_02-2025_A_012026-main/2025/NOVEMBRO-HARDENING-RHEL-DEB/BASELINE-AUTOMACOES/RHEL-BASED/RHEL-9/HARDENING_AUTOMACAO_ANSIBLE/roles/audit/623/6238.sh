#!/usr/bin/env bash

echo "235 Ensure rsyslog logrotate is configured"

{
    l_output=""
    l_rotate_conf=""

    if [ -f /etc/logrotate.conf ]; then
        l_rotate_conf="/etc/logrotate.conf"
    elif compgen -G "/etc/logrotate.d/*.conf" 2>/dev/null; then
        for file in /etc/logrotate.d/*.conf; do
            l_rotate_conf="$file"
        done
    elif systemctl is-active --quiet systemd-journal-upload.service; then
echo "ℹ️  INFO: journald está em uso no sistema - recomendação não se aplica."
        exit 0
    else
        l_output="${l_output}\n- rsyslog está em uso e logrotate NÃO está configurado."
    fi

    if [ -z "$l_output" ]; then
echo "✅ REVIEW: logrotate está configurado. Verifique se a rotação está conforme a política da organização.\nArquivo: $l_rotate_conf"
    else
echo "⚠️[REPROVADO]: $l_output"
    fi
}