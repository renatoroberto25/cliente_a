#!/usr/bin/env bash
echo "[46] Verificar se o SELinux está instalado"
rpm -q libselinux &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[47] Verificar se o SELinux não está desabilitado no bootloader"
grep -E '^\s*GRUB_CMDLINE_LINUX=.*selinux=0' /etc/default/grub &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[48] Verificar se a política do SELinux está configurada"
selinux_config="/etc/selinux/config"
grep -E '^\s*SELINUXTYPE=(targeted|mls)' "$selinux_config" &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[49] Verificar se o modo do SELinux não está desabilitado"
grep -E '^\s*SELINUX=disabled' "$selinux_config" &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[50] Verificar se o modo do SELinux está em enforcing"
sestatus | grep -q '^Current mode:\s*enforcing' && grep -q '^SELINUX=enforcing' "$selinux_config" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
