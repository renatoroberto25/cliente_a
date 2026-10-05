
#!/usr/bin/env bash
echo -e "\n[14] Verifique se core dumps estão restritos"
(ulimit -c 0 && sysctl -n fs.suid_dumpable | grep -q '^0$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[15] Verifique se ptrace_scope está restrito"
(sysctl -n kernel.yama.ptrace_scope | grep -q '^[1-3]$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[16] Verifique se NX/XD está ativo"
(grep -q 'nx' /proc/cpuinfo && dmesg | grep -qi 'NX.*active') && echo "✅ APROVADO" || echo "⚠️ REPROVADO (Possível ausência no hardware)"

echo -e "\n[17] Verifique se ASLR está habilitado"
(sysctl -n kernel.randomize_va_space | grep -q '^2$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[18] Verifique se IOMMU está ativo"
(grep -q 'iommu=on' /proc/cmdline) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[19] Verifique se perf_event está restrito"
(sysctl -n kernel.perf_event_paranoid | grep -q '^[2-3]$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[20] Verifique se dmesg está restrito"
(sysctl -n kernel.dmesg_restrict | grep -q '^1$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[21] Verifique se user namespace está desabilitado"
( sysctl -n kernel.unprivileged_userns_clone 2>/dev/null | grep -q '^0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[22] Verifique se protected_symlinks está habilitado"
(sysctl -n fs.protected_symlinks | grep -q '^1$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[23] Verifique se protected_hardlinks está habilitado"
(sysctl -n fs.protected_hardlinks | grep -q '^1$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[24] Verifique se suid_dumpable=0"
(sysctl -n fs.suid_dumpable | grep -q '^0$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
