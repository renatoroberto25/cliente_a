#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 1–14 (RHEL 7)"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

ensure_mod_disabled() {
  local mod="$1"

  if modinfo "$mod" >/dev/null 2>&1; then
    grep -q "^install ${mod} /bin/true" /etc/modprobe.d/hardening.conf 2>/dev/null || \
      echo "install ${mod} /bin/true" >> /etc/modprobe.d/hardening.conf

    grep -q "^blacklist ${mod}" /etc/modprobe.d/hardening.conf 2>/dev/null || \
      echo "blacklist ${mod}" >> /etc/modprobe.d/hardening.conf

    if lsmod | awk '{print $1}' | grep -qx "$mod"; then
      modprobe -r "$mod" 2>/dev/null || true
    fi

    echo " ${mod} desabilitado"
  else
    echo " ${mod} não presente no sistema"
  fi
}

MODFILE="/etc/modprobe.d/hardening.conf"
SYSCTLFILE="/etc/sysctl.d/99-hardening.conf"

touch "$MODFILE" "$SYSCTLFILE"
backup "$MODFILE"
backup "$SYSCTLFILE"

echo -e "\n[1-13] Desabilitar módulos inseguros"

ensure_mod_disabled "cramfs"
ensure_mod_disabled "freevxfs"
ensure_mod_disabled "jffs2"
ensure_mod_disabled "hfs"
ensure_mod_disabled "hfsplus"
ensure_mod_disabled "squashfs"
ensure_mod_disabled "udf"
ensure_mod_disabled "usb-storage"

echo -e "\n[14] Restringir core dumps"

if sysctl -n fs.suid_dumpable >/dev/null 2>&1; then
  if grep -q "^fs.suid_dumpable" "$SYSCTLFILE" 2>/dev/null; then
    sed -i 's/^fs.suid_dumpable.*/fs.suid_dumpable = 0/' "$SYSCTLFILE"
  else
    echo "fs.suid_dumpable = 0" >> "$SYSCTLFILE"
  fi
  sysctl -w fs.suid_dumpable=0 >/dev/null 2>&1 || true
  echo " fs.suid_dumpable = 0"
else
  echo " fs.suid_dumpable não suportado"
fi
