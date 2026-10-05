#!/usr/bin/env bash

echo -e "\n[58] Sincronização de tempo em uso"
( systemctl is-active --quiet chronyd &>/dev/null || systemctl is-active --quiet ntpd &>/dev/null || systemctl is-active --quiet systemd-timesyncd &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[59] Chrony configurado"
( ! rpm -q chrony &>/dev/null || ( systemctl is-enabled chronyd &>/dev/null && grep -q '^server' /etc/chrony.conf 2>/dev/null ) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[60] NTP configurado"
( ! rpm -q ntp &>/dev/null || ( systemctl is-enabled ntpd &>/dev/null && grep -q '^server' /etc/ntp.conf 2>/dev/null ) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
