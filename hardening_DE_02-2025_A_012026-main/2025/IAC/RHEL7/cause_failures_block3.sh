#!/bin/bash
set -e

# ==============================
# Logs — enfraquecer journald
# ==============================
JOUR="/etc/systemd/journald.conf"
[ ! -f ${JOUR}.bak.fail ] && cp -a "$JOUR" ${JOUR}.bak.fail
sed -i '/^SystemMaxUse/d' "$JOUR" || true
systemctl restart systemd-journald || true

echo "[BLOCO 3] Finalizado."
