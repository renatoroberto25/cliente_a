#!/usr/bin/env bash
set -uo pipefail   # removido -e (CRÍTICO)

############################################
# VARIÁVEIS
############################################
HOST=$(hostname)
DATE=$(date +%Y%m%d_%H%M%S)

LOG="/var/log/precheck_os.log"
CSV="/root/precheck_${HOST}_${DATE}.csv"

exec > >(tee -a "$LOG") 2>&1

STATUS="OK"
SCORE=0

############################################
# FUNÇÃO
############################################
log_check() {
    local name=$1
    local result=$2
    local weight=$3

    echo "$HOST,$name,$result,$weight" >> "$CSV"

    case "$result" in
        OK) SCORE=$((SCORE + weight)) ;;
        WARN) STATUS="WARN" ;;
        FAIL) STATUS="FAIL" ;;
    esac
}

############################################
# DETECÇÃO
############################################
if [ -f /etc/os-release ]; then
    OS_ID=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
    OS_VER=$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')
else
    echo "[ERRO] os-release não encontrado"
    exit 1
fi

MAJOR=$(echo "$OS_VER" | cut -d. -f1)
KERNEL=$(uname -r)

echo "[INFO] HOST=$HOST"
echo "[INFO] OS=$OS_ID VERSION=$OS_VER MAJOR=$MAJOR KERNEL=$KERNEL"

############################################
# OS SUPORTE
############################################
case "$OS_ID" in
    rhel|centos|ol|rocky|almalinux)
        log_check "OS_SUPPORT" "OK" 10
        ;;
    *)
        log_check "OS_SUPPORT" "FAIL" 10
        ;;
esac

############################################
# VERSÃO
############################################
[ "$MAJOR" -ge 6 ] 2>/dev/null \
    && log_check "OS_VERSION" "OK" 10 \
    || log_check "OS_VERSION" "FAIL" 10

############################################
# INIT SYSTEM
############################################
if command -v systemctl >/dev/null 2>&1; then
    INIT="systemd"
    log_check "INIT_SYSTEM" "OK" 5
else
    INIT="init"
    log_check "INIT_SYSTEM" "LEGACY" 5
fi

############################################
# AUTHSELECT
############################################
if [ "$MAJOR" -ge 8 ]; then
    if command -v authselect >/dev/null 2>&1; then
        authselect check >/dev/null 2>&1 \
            && log_check "AUTHSELECT" "OK" 10 \
            || log_check "AUTHSELECT" "CUSTOM" 5
    else
        log_check "AUTHSELECT" "MISSING" 5
    fi
else
    log_check "AUTHSELECT" "LEGACY" 5
fi

############################################
# SSH
############################################
sshd -t >/dev/null 2>&1 \
    && log_check "SSHD_CONFIG" "OK" 10 \
    || log_check "SSHD_CONFIG" "FAIL" 10

############################################
# AUDITD
############################################
systemctl is-enabled auditd >/dev/null 2>&1 \
    && log_check "AUDITD" "OK" 10 \
    || log_check "AUDITD" "WARN" 5

############################################
# DISCO
############################################
ROOT_USAGE=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

if [ "$ROOT_USAGE" -lt 90 ] 2>/dev/null; then
    log_check "DISK_ROOT" "OK" 10
else
    log_check "DISK_ROOT" "CRITICAL" 0
fi

############################################
# RPM
############################################
command -v rpm >/dev/null 2>&1 \
    && log_check "RPM" "OK" 5 \
    || log_check "RPM" "FAIL" 5

############################################
# RSYSLOG (importante pro teu SIEM)
############################################
systemctl is-active rsyslog >/dev/null 2>&1 \
    && log_check "RSYSLOG" "OK" 10 \
    || log_check "RSYSLOG" "WARN" 5

############################################
# SCORE FINAL
############################################
echo "$HOST,PRECHECK_SCORE,$SCORE" >> "$CSV"
echo "$HOST,PRECHECK_STATUS,$STATUS" >> "$CSV"

echo "================================"
echo "PRECHECK SCORE: $SCORE"
echo "STATUS: $STATUS"
echo "CSV: $CSV"
echo "================================"

############################################
# DECISÃO
############################################
if [ "$STATUS" = "FAIL" ]; then
    echo "[BLOCK] hardening NÃO deve rodar"
    exit 1
else
    echo "[ALLOW] seguro para hardening"
    exit 0
fi