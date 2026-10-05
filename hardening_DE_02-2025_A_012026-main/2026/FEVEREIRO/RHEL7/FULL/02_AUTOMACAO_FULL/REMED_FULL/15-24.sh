#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 15–24 (RHEL 7)"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

set_sysctl() {
  local key="$1"
  local val="$2"
  local file="$3"

  if sysctl -n "$key" >/dev/null 2>&1; then
    if grep -q "^${key}" "$file" 2>/dev/null; then
      sed -i "s|^${key}.*|${key} = ${val}|" "$file"
    else
      echo "${key} = ${val}" >> "$file"
    fi
    sysctl -w "${key}=${val}" >/dev/null 2>&1 || true
    echo " ${key} = ${val}"
  else
    echo " ${key} não suportado neste kernel"
  fi
}

SYSCTLFILE="/etc/sysctl.d/99-hardening.conf"
touch "$SYSCTLFILE"
backup "$SYSCTLFILE"

echo -e "\n[15] ptrace_scope restrito"
set_sysctl "kernel.yama.ptrace_scope" "1" "$SYSCTLFILE"

echo -e "\n[16] NX/XD (verificação informativa)"
if grep -qi ' nx ' /proc/cpuinfo; then
  echo " Hardware suporta NX"
else
  echo " Hardware não suporta NX"
fi

echo -e "\n[17] ASLR habilitado"
set_sysctl "kernel.randomize_va_space" "2" "$SYSCTLFILE"

echo -e "\n[18] IOMMU (fora do escopo automático)"
echo " Requer ajuste em GRUB manualmente se aplicável"

echo -e "\n[19] perf_event restrito"
set_sysctl "kernel.perf_event_paranoid" "2" "$SYSCTLFILE"

echo -e "\n[20] dmesg restrito"
set_sysctl "kernel.dmesg_restrict" "1" "$SYSCTLFILE"

echo -e "\n[21] user namespaces restritos"
set_sysctl "user.max_user_namespaces" "0" "$SYSCTLFILE"

echo -e "\n[22] protected_symlinks"
set_sysctl "fs.protected_symlinks" "1" "$SYSCTLFILE"

echo -e "\n[23] protected_hardlinks"
set_sysctl "fs.protected_hardlinks" "1" "$SYSCTLFILE"

echo -e "\n[24] suid_dumpable reforçado"
set_sysctl "fs.suid_dumpable" "0" "$SYSCTLFILE"
