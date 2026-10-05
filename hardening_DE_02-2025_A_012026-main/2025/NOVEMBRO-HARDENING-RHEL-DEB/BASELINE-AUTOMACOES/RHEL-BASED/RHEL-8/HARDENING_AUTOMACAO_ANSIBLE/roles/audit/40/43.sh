#!/usr/bin/env bash
echo "[43 - 45] Ativar ASLR (kernel.randomize_va_space = 2)"

echo "[43] Ensure ptrace_scope is restricted"
[ "$(sysctl -n kernel.yama.ptrace_scope 2>/dev/null)" = "1" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[44] Ensure core dump backtraces are disabled"
grep -Pq '^\s*ProcessSizeMax\s*=\s*0' /etc/systemd/coredump.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[45] Ensure core dump storage is disabled"
grep -Pq '^\s*Storage\s*=\s*none' /etc/systemd/coredump.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"