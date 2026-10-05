#!/usr/bin/env bash
# [30-31] Audit HITSS - AIDE (versão simplificada)
# Servidores baseados em RHEL 7 — KEEP IT SIMPLE
set -euo pipefail

echo -e "\n[30] Verifique se o AIDE está instalado"
rpm -q aide &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[31] Verifique se há agendamento periódico de verificação de integridade"
if grep -q "/usr/sbin/aide" /etc/cron.daily/aide 2>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi
