#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[52 - 57] MAC e serviços legados"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

PKG_RM() {
  if command -v dnf >/dev/null 2>&1; then
    dnf remove -y "$@" >/dev/null 2>&1
  else
    yum remove -y "$@" >/dev/null 2>&1
  fi
}

CONFIG="/etc/selinux/config"
backup "$CONFIG"

echo -e "\n[52] SELinux enforcing (configuração)"

if grep -q '^SELINUX=' "$CONFIG"; then
  sed -i 's/^SELINUX=.*/SELINUX=enforcing/' "$CONFIG"
else
  echo "SELINUX=enforcing" >> "$CONFIG"
fi

CUR_STATE="$(getenforce 2>/dev/null || echo Disabled)"

if echo "$CUR_STATE" | grep -qi '^Disabled$'; then
  echo " SELinux Disabled no runtime — reboot necessário"
else
  setenforce 1 >/dev/null 2>&1 || true
  echo " SELinux em Enforcing (runtime)"
fi

echo -e "\n[53] SELinux policy targeted"

if grep -q '^SELINUXTYPE=' "$CONFIG"; then
  sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' "$CONFIG"
else
  echo "SELINUXTYPE=targeted" >> "$CONFIG"
fi

echo " SELINUXTYPE=targeted configurado"

echo -e "\n[54] Serviços em unconfined_service_t"

if getenforce 2>/dev/null | grep -q Enforcing; then
  SVC=$(ps -eZ 2>/dev/null | awk '$1 ~ /unconfined_service_t/ {print $NF}' | sort -u)
  if [ -n "${SVC:-}" ]; then
    echo " Serviços não confinados detectados:"
    echo "$SVC"
    echo " Ação manual requerida (política SELinux)"
  else
    echo " Nenhum serviço unconfined_service_t"
  fi
else
  echo " SELinux não está em Enforcing — verificação limitada"
fi

echo -e "\n[55] Processos em unconfined_t"

if getenforce 2>/dev/null | grep -q Enforcing; then
  PROC=$(ps -eZ 2>/dev/null | awk '$1 ~ /unconfined_t/ {print $NF}' | sort -u)
  if [ -n "${PROC:-}" ]; then
    echo " Processos não confinados detectados:"
    echo "$PROC"
    echo " Ação manual requerida (contexto SELinux)"
  else
    echo " Nenhum processo unconfined_t"
  fi
else
  echo " SELinux não está em Enforcing — verificação limitada"
fi

echo -e "\n[56] Prelink"

if rpm -q prelink &>/dev/null; then
  command -v prelink >/dev/null 2>&1 && prelink -ua >/dev/null 2>&1 || true
  PKG_RM prelink || true
  echo " prelink removido"
else
  echo " prelink não instalado"
fi

echo -e "\n[57] xinetd"

if rpm -q xinetd &>/dev/null; then
  PKG_RM xinetd || true
  rm -f /etc/xinetd.conf /etc/xinetd.d/* 2>/dev/null || true
  echo " xinetd removido"
else
  echo " xinetd não instalado"
fi

