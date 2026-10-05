
#!/usr/bin/env bash

echo -e "\n[58] Sincronização de tempo em uso"
( systemctl is-active --quiet chronyd &>/dev/null || \
  systemctl is-active --quiet ntpd &>/dev/null || \
  systemctl is-active --quiet systemd-timesyncd &>/dev/null ) && \
  echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[59] Chrony configurado"
( ! dpkg -l | grep -q '^ii\s\+chrony' || \
  ( systemctl is-enabled chronyd &>/dev/null && \
    grep -q '^server' /etc/chrony/chrony.conf 2>/dev/null ) ) && \
  echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[60] NTP configurado"
( ! dpkg -l | grep -q '^ii\s\+ntp' || \
  ( systemctl is-enabled ntpd &>/dev/null && \
    grep -q '^server' /etc/ntp.conf 2>/dev/null ) ) && \
  echo "✅ APROVADO"

#MUDAR NO TENABLE AUDIT