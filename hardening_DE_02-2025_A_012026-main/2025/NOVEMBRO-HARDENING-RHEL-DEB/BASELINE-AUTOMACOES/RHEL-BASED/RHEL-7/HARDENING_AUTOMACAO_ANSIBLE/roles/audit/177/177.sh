#!/usr/bin/env bash
echo "[177–178] Verificações de configuração do sudo"

# 177 - Ensure sudo commands use pty
echo "[177] Verifique se o sudo está configurado para usar pseudo-TTY"
grep -Eq '^[[:space:]]*Defaults[[:space:]]+([^#[:space:]]+,\s*)?use_pty\b' /etc/sudoers /etc/sudoers.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 178 - Ensure sudo log file exists
echo "[178] Verifique se há log customizado do sudo"
grep -Eq '^[[:space:]]*Defaults[[:space:]]+([^#;]+,\s*)?logfile\s*=\s*(")?[^#;]+(")?' /etc/sudoers /etc/sudoers.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"