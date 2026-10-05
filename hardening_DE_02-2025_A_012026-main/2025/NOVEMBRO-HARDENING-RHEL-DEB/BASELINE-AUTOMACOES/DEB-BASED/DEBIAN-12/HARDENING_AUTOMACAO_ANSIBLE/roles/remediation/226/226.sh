#!/usr/bin/env bash
# remed_hitss_226.sh
# Remediação HITSS 226-236 (journald) - Debian 12
# Mantém journald como sistema de logging principal

set -euo pipefail
TS="$(date +%Y%m%d_%H%M%S)"
CONF_DIR="/etc/systemd/journald.conf.d"
mkdir -p "$CONF_DIR"

_backup_file() {
  local f="$1"
  [ -f "$f" ] && cp -a "$f" "${f}.bak_${TS}"
}

echo "[226] Garantindo journald ativo"
systemctl unmask systemd-journald.service 2>/dev/null || true
systemctl enable --now systemd-journald.service

echo "[227] Ajustando permissões do journald"
find /var/log/journal -type f -name "*.journal" 2>/dev/null | while read -r f; do
  [ "$(stat -Lc '%a' "$f")" -gt 640 ] && chmod 0640 "$f"
done
chown -R root:systemd-journal /var/log/journal/* 2>/dev/null || true
chmod 0755 /run/log/journal 2>/dev/null || true
chmod 2755 /var/log/journal/* 2>/dev/null || true

echo "[228] Configurando rotação"
ROT_FILE="$CONF_DIR/99-rotation.conf"
if ! grep -Psiq '^\s*(SystemMaxUse|SystemKeepFree|RuntimeMaxUse|RuntimeKeepFree|MaxFileSec)=' \
   /etc/systemd/journald.conf "$CONF_DIR"/*.conf 2>/dev/null; then
  _backup_file "$ROT_FILE"
  cat > "$ROT_FILE" <<EOF
[Journal]
SystemMaxUse=500M
SystemKeepFree=50M
RuntimeMaxUse=200M
RuntimeKeepFree=30M
MaxFileSec=1month
EOF
fi

echo "[229] Garantindo apenas journald"
if systemctl is-active --quiet rsyslog; then
  systemctl stop rsyslog
  systemctl disable rsyslog
fi

echo "[230] Instalando systemd-journal-remote (se ausente)"
dpkg -s systemd-journal-remote &>/dev/null || apt-get update -qq && apt-get install -y -qq systemd-journal-remote

echo "[231] Configuração básica journal-upload"
echo -e "\n Configurar conforme logserver"
#AUTH_FILE="/etc/systemd/journal-upload.conf.d/99-auth.conf"
#mkdir -p /etc/systemd/journal-upload.conf.d
#if ! grep -Psiq '^\s*(URL|ServerKeyFile|ServerCertificateFile|TrustedCertificateFile)=' \
#   /etc/systemd/journal-upload.conf /etc/systemd/journal-upload.conf.d/*.conf 2>/dev/null; then
#  _backup_file "$AUTH_FILE"
#  cat > "$AUTH_FILE" <<EOF
#[Upload]
#URL=https://logserver.exemplo:19532
#ServerKeyFile=/etc/ssl/private/journal-upload.key
#ServerCertificateFile=/etc/ssl/certs/journal-upload.crt
#TrustedCertificateFile=/etc/ssl/certs/logserver-ca.pem
#EOF
#fi

echo "[232] Garantindo journal-upload ativo"
systemctl enable --now systemd-journal-upload.service 2>/dev/null || true

echo "[233] Desabilitando systemd-journal-remote"
systemctl disable --now systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null || true
systemctl mask systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null || true

echo "[234] ForwardToSyslog=no"
FWD_FILE="$CONF_DIR/99-forward.conf"
grep -Psiq '^\s*ForwardToSyslog=no\b' /etc/systemd/journald.conf "$CONF_DIR"/*.conf 2>/dev/null || {
  _backup_file "$FWD_FILE"
  echo -e "[Journal]\nForwardToSyslog=no" > "$FWD_FILE"
}

echo "[235] Compress=yes"
CMP_FILE="$CONF_DIR/99-compress.conf"
grep -Psiq '^\s*Compress=yes\b' /etc/systemd/journald.conf "$CONF_DIR"/*.conf 2>/dev/null || {
  _backup_file "$CMP_FILE"
  echo -e "[Journal]\nCompress=yes" > "$CMP_FILE"
}

echo "[236] Storage=persistent"
STO_FILE="$CONF_DIR/99-storage.conf"
grep -Psiq '^\s*Storage=persistent\b' /etc/systemd/journald.conf "$CONF_DIR"/*.conf 2>/dev/null || {
  _backup_file "$STO_FILE"
  echo -e "[Journal]\nStorage=persistent" > "$STO_FILE"
}

systemctl daemon-reexec
systemctl restart systemd-journald
echo "== Remediação concluída =="