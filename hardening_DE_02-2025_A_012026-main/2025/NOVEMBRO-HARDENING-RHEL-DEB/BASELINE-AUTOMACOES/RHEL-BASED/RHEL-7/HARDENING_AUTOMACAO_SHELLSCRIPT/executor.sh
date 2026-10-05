#!/usr/bin/env bash
# executor.sh - Rodar auditoria e remediação Light de forma interativa
# Estrutura: ~/hardening-ol7-light/{audit,remed,logs}

BASE_DIR="$(dirname "$(realpath "$0")")"
AUDIT_DIR="$BASE_DIR/audit"
REMED_DIR="$BASE_DIR/remed"
LOG_AUDIT="$BASE_DIR/logs/audit"
LOG_REMED="$BASE_DIR/logs/remed"

HOSTNAME=$(hostname -s)
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$LOG_AUDIT" "$LOG_REMED"

run_scripts() {
    local DIR="$1"
    local LOG="$2"
    echo "▶ Executando scripts em: $DIR"
    for shfile in $(ls "$DIR"/*.sh 2>/dev/null | sort -V); do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG"
        echo "▶ Rodando: $(basename "$shfile")" | tee -a "$LOG"
        bash "$shfile" 2>&1 | tee -a "$LOG"
        echo "" | tee -a "$LOG"
    done
    echo "✔ Concluído, log salvo em: $LOG"
}

# 1. Audit pré-hardening
LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
echo "=== AUDIT PRE-HARDENING ===" | tee "$LOG_PRE"
run_scripts "$AUDIT_DIR" "$LOG_PRE"

# 2. Perguntar se deseja continuar
read -rp "Deseja continuar para remediações? (s/N): " RESP
if [[ "$RESP" =~ ^[Ss]$ ]]; then
    # 2.1 Rodar remed
    LOG_REMED_FILE="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
    echo "=== REMEDIAÇÕES ===" | tee "$LOG_REMED_FILE"
    run_scripts "$REMED_DIR" "$LOG_REMED_FILE"

    # 2.2 Rodar audit pós-hardening
    LOG_POST="$LOG_AUDIT/audit-post-${HOSTNAME}-${DATE}.log"
    echo "=== AUDIT PÓS-HARDENING ===" | tee "$LOG_POST"
    run_scripts "$AUDIT_DIR" "$LOG_POST"
else
    echo "❗ Execução encerrada após o pré-hardening."
fi
