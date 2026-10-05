#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[58 - 60] Remediação: Sincronização de tempo"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

PKG_INSTALL() {
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y "$@" >/dev/null 2>&1
  else
    yum install -y "$@" >/dev/null 2>&1
  fi
}

PKG_REMOVE() {
  if command -v dnf >/dev/null 2>&1; then
    dnf remove -y "$@" >/dev/null 2>&1
  else
    yum remove -y "$@" >/dev/null 2>&1
  fi
}

echo -e "\n[58] Garantir serviço de sincronização de tempo ativo"

if systemctl list-unit-files 2>/dev/null | grep -q '^systemd-timesyncd.service'; then
  systemctl stop systemd-timesyncd 2>/dev/null || true
  systemctl disable systemd-timesyncd 2>/dev/null || true
fi

rpm -q chrony &>/dev/null || PKG_INSTALL chrony

systemctl enable chronyd --now >/dev/null 2>&1 || true

if systemctl is-active chronyd &>/dev/null; then
  echo " Serviço de tempo ativo (chronyd)"
else
  echo " Nenhum serviço de tempo ativo"
fi

echo -e "\n[59] Configurar Chrony corretamente"

CONF="/etc/chrony.conf"
backup "$CONF"

if ! grep -Eq '^\s*server\s+' "$CONF" 2>/dev/null; then
  echo "server time.google.com iburst" >> "$CONF"
  echo " Servidor NTP padrão configurado"
else
  echo " Servidor NTP já configurado"
fi

systemctl restart chronyd >/dev/null 2>&1 || true
echo " Chrony configurado"

echo -e "\n[60] Remover NTP clássico (ntpd)"

if rpm -q ntp &>/dev/null; then
  systemctl stop ntpd >/dev/null 2>&1 || true
  systemctl disable ntpd >/dev/null 2>&1 || true
  PKG_REMOVE ntp
  echo " NTP removido"
else
  echo " NTP não está instalado"
fi
