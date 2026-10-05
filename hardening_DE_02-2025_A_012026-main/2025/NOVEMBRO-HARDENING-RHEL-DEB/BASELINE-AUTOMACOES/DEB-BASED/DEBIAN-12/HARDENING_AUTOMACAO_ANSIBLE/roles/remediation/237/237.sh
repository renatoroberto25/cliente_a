#!/usr/bin/env bash
# remed_rsyslog_237_245.sh
# Remediações idempotentes para HITSS 237-245 (Debian-like)
# Execute em ambiente de testes primeiro.
set -euo pipefail

TS="$(date +%Y%m%d_%H%M%S)"
CHANGED=0

echo
echo "== Remediação rsyslog (237-245) - início: $(date) =="

# helper: backup file if exists
_backup_file() {
  local f="$1"
  if [ -f "$f" ]; then
    cp -a "$f" "${f}.bak_${TS}"
    echo "  backup: ${f} -> ${f}.bak_${TS}"
  fi
}

# [237] Ensure rsyslog is installed
echo -e "\n[237] Garantindo pacote rsyslog"
if ! dpkg -s rsyslog &>/dev/null; then
  echo "  Instalando rsyslog..."
  apt-get update -qq && apt-get install -y -qq rsyslog
  CHANGED=1
else
  echo "  OK: rsyslog já instalado"
fi

# [238] Ensure rsyslog service is enabled/active
echo -e "\n[238] Garantindo serviço rsyslog habilitado/ativo"
if systemctl list-unit-files | grep -q '^rsyslog.service'; then
  if ! systemctl is-enabled --quiet rsyslog || ! systemctl is-active --quiet rsyslog; then
    systemctl unmask rsyslog.service 2>/dev/null || true
    systemctl enable --now rsyslog.service
    CHANGED=1
    echo "  OK: rsyslog habilitado e iniciado"
  else
    echo "  OK: rsyslog já habilitado e ativo"
  fi
else
  echo "  AVISO: rsyslog.service não encontrado"
fi

# [239] Ensure journald sends logs to rsyslog
echo -e "\n[239] Garantindo ForwardToSyslog=yes em journald"
JCONF="/etc/systemd/journald.conf.d/99-forward.conf"
mkdir -p /etc/systemd/journald.conf.d
if ! grep -Psiq '^\s*ForwardToSyslog=yes\b' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null; then
  _backup_file "$JCONF"
  echo -e "[Journal]\nForwardToSyslog=yes" > "$JCONF"
  CHANGED=1
  echo "  Ajustado: ForwardToSyslog=yes"
  systemctl restart systemd-journald
else
  echo "  OK: ForwardToSyslog já configurado"
fi

# [240] Ensure rsyslog $FileCreateMode 0640
echo -e "\n[240] Garantindo \$FileCreateMode 0640 no rsyslog"
RCONF="/etc/rsyslog.d/99-filecreatemode.conf"
if ! grep -Psiq '^\s*\$FileCreateMode\s+0640\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
  _backup_file "$RCONF"
  echo "\$FileCreateMode 0640" > "$RCONF"
  CHANGED=1
  echo "  Ajustado: \$FileCreateMode 0640"
  systemctl restart rsyslog
else
  echo "  OK: \$FileCreateMode já configurado"
fi

# [241] Logging adequadamente configurado -> instrução
echo -e "\n[241] (INSTRUÇÃO) Verifique regras de logging em /etc/rsyslog.conf e /etc/rsyslog.d/*"
echo "  Ex.: *.info;mail.none;authpriv.none;cron.none /var/log/messages"

# [242] Envio a host remoto -> instrução
echo -e "\n[242] (INSTRUÇÃO) Configure envio remoto se necessário:"
echo "  Ex.: *.* @@loghost.exemplo.com"

# [243] Ensure rsyslog not receiving remote logs
echo -e "\n[243] Garantindo que rsyslog não receba logs remotos"
if grep -Eiq '^\s*(\$ModLoad\s+imtcp|\$InputTCPServerRun)' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
  echo "  Ajustando: comentando entradas de recepção remota"
  sed -i.bak_${TS} -E 's/^\s*(\$ModLoad\s+imtcp)/#\1/' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null || true
  sed -i -E 's/^\s*(\$InputTCPServerRun)/#\1/' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null || true
  systemctl restart rsyslog
  CHANGED=1
else
  echo "  OK: rsyslog não está configurado para receber logs"
fi

# [244] logrotate -> instrução
echo -e "\n[244] (INSTRUÇÃO) Confirme existência e regras em /etc/logrotate.conf e /etc/logrotate.d/*"

# [245] Ensure log file permissions <=0640
echo -e "\n[245] Ajustando permissões de arquivos em /var/log"
find /var/log -type f -exec stat -Lc '%n %a' {} \; 2>/dev/null | while read -r f p; do
  if [ "$p" -gt 640 ]; then
    chmod 0640 "$f"
    echo "  Corrigido: $f -> 0640"
    CHANGED=1
  fi
done

echo
echo "== Resumo rsyslog =="
if [ "$CHANGED" -eq 1 ]; then
  echo "  Alterações aplicadas. Backups com sufixo .bak_${TS}."
else
  echo "  Nenhuma alteração necessária (já conforme)."
fi

echo "== Fim: $(date) =="
exit 0