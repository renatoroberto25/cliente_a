#!/usr/bin/env bash

echo -e "\n[89] Apenas um daemon de time sync"
( ( systemctl is-active --quiet chronyd &>/dev/null && ! systemctl is-active --quiet ntpd &>/dev/null && ! systemctl is-active --quiet systemd-timesyncd &>/dev/null ) || ( ! systemctl is-active --quiet chronyd &>/dev/null && systemctl is-active --quiet ntpd &>/dev/null && ! systemctl is-active --quiet systemd-timesyncd &>/dev/null ) || ( ! systemctl is-active --quiet chronyd &>/dev/null && ! systemctl is-active --quiet ntpd &>/dev/null && systemctl is-active --quiet systemd-timesyncd &>/dev/null ) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[90] Cron/at seguros e restritos"
(stat -Lc '%a %U %G' /etc/cron.allow 2>/dev/null | grep -Eq '^640 root (root|crontab)$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")
