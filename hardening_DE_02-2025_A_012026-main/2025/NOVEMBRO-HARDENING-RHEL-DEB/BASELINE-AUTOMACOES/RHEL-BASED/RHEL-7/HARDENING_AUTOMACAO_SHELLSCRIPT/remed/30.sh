#!/usr/bin/env bash
# [30-31] Remediação HITSS - AIDE (Servidores baseados em RHEL 7)
# Objetivo: executar exatamente o que o audit_hitss_30-31.sh verifica.
# - Instala AIDE se não instalado.
# - Cria cron detectável pelo audit (sem lógicas extras).
# - Idempotente e estritamente compatível com o audit.
set -euo pipefail

ok(){ echo "[OK] $*"; }
warn(){ echo "[WARN] $*"; }

echo -e "\n[30] Verifique se o AIDE está instalado"
if rpm -q aide &>/dev/null; then
  ok "AIDE já instalado"
else
  yum install -y aide && ok "AIDE instalado via yum"
fi

echo -e "\n[31] Verifique se há agendamento periódico de verificação de integridade"
# o audit procura o termo "aide" dentro de /etc/cron.* → o cron precisa conter exatamente isso
if grep -Ersq '^([^#]+\s+)?(\/usr\/s?bin\/|^\s*)aide(\.wrapper)?\s(--?\S+\s)*(- -(check|update)|\$AIDEARGS)\b' /etc/cron.* /etc/crontab /var/spool/cron/ \
  || (systemctl is-enabled aidecheck.timer &>/dev/null && systemctl is-active aidecheck.timer &>/dev/null); then
  ok "Agendamento AIDE já existente"
else
  CRON_FILE="/etc/cron.daily/aide"
  echo "/usr/sbin/aide --check" > "$CRON_FILE"
  chmod 755 "$CRON_FILE"
  ok "Cron criado: $CRON_FILE"
fi
