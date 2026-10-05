#!/bin/bash

#curl -H 'X-Key: 45b85b603d4f4ed07d445151eacc6db46715a19318c42da539327de707dedbac' 'https://sensor.cloud.tenable.com/install/scanner?name=oraclelinux9-lab&groups=LAB_Linux_scanner' | bash
set -euo pipefail

FLAG_FILE="/var/lib/tenable/nessus/.first-boot-done"
T_KEY="${T_KEY:-45b85b603d4f4ed07d445151eacc6db46715a19318c42da539327de707dedbac}"
T_HOST="${T_HOST:-sensor.cloud.tenable.com}"
T_PORT="${T_PORT:-443}"
T_GROUPS="${T_GROUPS:-LAB_Linux_scanner}"
HNAME="${HNAME:-$(hostname -s 2>/dev/null || hostname)}"
CLI="/opt/nessus/sbin/nessuscli"

if timeout 10 bash -c "</dev/tcp/${T_HOST}/${T_PORT}" >/dev/null 2>&1; then
    echo "[OK] Conectividade direta OK"
else
    echo "[ERRO] Sem conectividade direta com ${T_HOST}:${T_PORT}"
    exit 1
fi

if [ ! -x "$CLI" ]; then
    echo "[INFO] Nessus Scanner nao encontrado"
    echo "[INFO] Iniciando instalacao"

    curl -fsSL \
        -H "X-Key: ${T_KEY}" \
        "https://${T_HOST}/install/scanner?name=${HNAME}&groups=${T_GROUPS}" | bash

    sleep 10
else
    echo "[INFO] Nessus Scanner ja instalado - pulando instalacao"
fi

if [ -x "$CLI" ]; then
    systemctl enable nessusd >/dev/null 2>&1 || true
    systemctl restart nessusd >/dev/null 2>&1 || true

    sleep 5

    STATUS=$(systemctl is-active nessusd 2>/dev/null || true)

    if [ "$STATUS" = "active" ]; then
        echo "[OK] Nessus Scanner ativo"

        mkdir -p "$(dirname "$FLAG_FILE")"
        touch "$FLAG_FILE"

        echo
        echo "==============================="
        echo "STATUS FINAL"
        echo "==============================="
        systemctl status nessusd --no-pager

        exit 0
    else
        echo "[ERRO] Nessus Scanner instalado, mas serviço nao esta ativo"

        echo
        echo "==============================="
        echo "STATUS FINAL"
        echo "==============================="
        systemctl status nessusd --no-pager || true

        exit 1
    fi
else
    echo "[ERRO] nessuscli nao encontrado em ${CLI}"
    exit 1
fi