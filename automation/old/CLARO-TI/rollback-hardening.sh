#!/usr/bin/env bash

ROLLBACK_DIR="$1"

if [ -z "$ROLLBACK_DIR" ]; then
    echo "Uso: $0 /root/hardening_v2_rollback_xxx"
    exit 1
fi

echo "[INFO] Restaurando de $ROLLBACK_DIR"

cp -rp $ROLLBACK_DIR/* /

echo "[INFO] Restaurando serviços"

systemctl restart sshd
systemctl restart auditd
systemctl restart rsyslog

echo "[OK] rollback concluído"