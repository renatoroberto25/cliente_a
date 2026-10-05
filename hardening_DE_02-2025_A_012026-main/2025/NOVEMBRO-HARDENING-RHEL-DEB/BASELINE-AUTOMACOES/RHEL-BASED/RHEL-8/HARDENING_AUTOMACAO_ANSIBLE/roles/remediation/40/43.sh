#!/usr/bin/env bash
echo -e "\n [43 - 45] Restringir ptrace_scope, desabilitar backtraces e core dump storage"

echo "[43] Remediar kernel.yama.ptrace_scope = 1"
sysctl_file="/etc/sysctl.d/99-cis.conf"
grep -q "^kernel.yama.ptrace_scope" "$sysctl_file" 2>/dev/null || echo "kernel.yama.ptrace_scope = 1" >> "$sysctl_file"
sysctl -w kernel.yama.ptrace_scope=1
echo "[44] Desabilitar backtrace em core dumps"
conf="/etc/systemd/coredump.conf"
backup="${conf}.bak.$(date +%F_%H%M%S)"
cp "$conf" "$backup" 2>/dev/null
grep -q '^ProcessSizeMax=' "$conf" && \
  sed -i 's/^ProcessSizeMax=.*/ProcessSizeMax=0/' "$conf" || \
  echo "ProcessSizeMax=0" >> "$conf"
echo "[45] Desabilitar armazenamento de core dumps"
conf="/etc/systemd/coredump.conf"
backup="${conf}.bak.$(date +%F_%H%M%S)"
cp "$conf" "$backup" 2>/dev/null
grep -q '^Storage=' "$conf" && \
  sed -i 's/^Storage=.*/Storage=none/' "$conf" || \
  echo "Storage=none" >> "$conf"