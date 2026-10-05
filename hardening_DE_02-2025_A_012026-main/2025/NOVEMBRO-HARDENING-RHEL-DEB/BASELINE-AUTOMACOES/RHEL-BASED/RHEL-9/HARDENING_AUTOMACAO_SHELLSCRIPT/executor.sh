#!/usr/bin/env bash
# executor.sh - Rodar auditoria e remediação Light de forma interativa
# Estrutura: ~/hardening-ol8-light/{audit,remed,logs}

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

# ===============================
# Menu inicial
# ===============================
echo "=== HARDENING LIGHT - $(hostname -s) ==="
echo "1) Rodar auditoria (pré)"
echo "2) Rodar remediações"
echo "3) Rodar auditoria + remediações + auditoria pós"
echo "q) Sair"
read -rp "Escolha uma opção: " OPT

case "$OPT" in
    1)
        LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
        echo "=== AUDIT PRE-HARDENING ===" | tee "$LOG_PRE"
        run_scripts "$AUDIT_DIR" "$LOG_PRE"

        # Resumo do pré
        if [[ -f "$LOG_PRE" ]]; then
            echo ""
            echo "=== RESUMO DO AUDIT PRE-HARDENING ==="
            TOTAL_APROVADO=$(grep -c "APROVADO" "$LOG_PRE")
            TOTAL_REPROVADO=$(grep -c "REPROVADO" "$LOG_PRE")
            echo "✅ Aprovados : $TOTAL_APROVADO"
            echo "❌ Reprovados: $TOTAL_REPROVADO"
            echo "📄 Log: $LOG_PRE"
        fi
        ;;
    2)
        LOG_REMED_FILE="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
        echo "=== REMEDIAÇÕES ===" | tee "$LOG_REMED_FILE"
        run_scripts "$REMED_DIR" "$LOG_REMED_FILE"
        ;;
    3)
        # Pré
        LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
        echo "=== AUDIT PRE-HARDENING ===" | tee "$LOG_PRE"
        run_scripts "$AUDIT_DIR" "$LOG_PRE"

        # Remed
        LOG_REMED_FILE="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
        echo "=== REMEDIAÇÕES ===" | tee "$LOG_REMED_FILE"
        run_scripts "$REMED_DIR" "$LOG_REMED_FILE"

        # Pós
        LOG_POST="$LOG_AUDIT/audit-post-${HOSTNAME}-${DATE}.log"
        echo "=== AUDIT PÓS-HARDENING ===" | tee "$LOG_POST"
        run_scripts "$AUDIT_DIR" "$LOG_POST"

        # Comparativo pré x pós
        if [[ -f "$LOG_PRE" && -f "$LOG_POST" ]]; then
            echo ""
            echo "=== COMPARATIVO PRÉ x PÓS HARDENING ==="
            PRE_OK=$(grep -c "APROVADO" "$LOG_PRE")
            PRE_FAIL=$(grep -c "REPROVADO" "$LOG_PRE")
            POST_OK=$(grep -c "APROVADO" "$LOG_POST")
            POST_FAIL=$(grep -c "REPROVADO" "$LOG_POST")

            echo "Antes:  ✅ $PRE_OK  | ❌ $PRE_FAIL"
            echo "Depois: ✅ $POST_OK | ❌ $POST_FAIL"

            IMPROVEMENT=$((PRE_FAIL - POST_FAIL))
            if (( IMPROVEMENT > 0 )); then
                echo "✔ Melhorou em $IMPROVEMENT controles"
            elif (( IMPROVEMENT == 0 )); then
                echo "⚠️ Nenhuma melhoria detectada"
            else
                echo "❌ Houve regressão (mais reprovações após remed)"
            fi

            echo "📄 Logs: $LOG_PRE / $LOG_POST"
        fi
        ;;
    q|Q) echo "Saindo..." && exit 0 ;;
    *) echo "Opção inválida." && exit 1 ;;
esac