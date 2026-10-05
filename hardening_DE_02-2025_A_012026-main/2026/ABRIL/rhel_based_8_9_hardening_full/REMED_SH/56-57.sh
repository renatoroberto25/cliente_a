#!/usr/bin/env bash
set -u

echo "[56 - 57] serviços legados"

backup() {
  local f="$1"
  [ -f "$f" ] || return 0
  local ts
  ts="$(date +%Y%m%d%H%M%S)"
  cp -a "$f" "${f}.bak.${ts}" 2>/dev/null || true
}

PKG_RM() {
  if command -v dnf >/dev/null 2>&1; then
    dnf remove -y "$@" >/dev/null 2>&1
  else
    yum remove -y "$@" >/dev/null 2>&1
  fi
}

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

echo "OK"
exit 0
