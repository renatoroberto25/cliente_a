#!/usr/bin/env bash
# executor.sh - Orquestrador genérico de auditoria e remediação Hardening
# Estrutura obrigatória:
#   ./AUDIT/*.sh
#   ./REMED_FULL/*.sh OU LIGHT
#   ./logs/audit/
#   ./logs/remed/

BASE_DIR="$(dirname "$(realpath "$0")")"

AUDIT_DIR="$BASE_DIR/AUDIT"
#MUDAR CONFORME NECESSIDADE
REMED_DIR="$BASE_DIR/REMED_FULL"

LOG_DIR="$BASE_DIR/logs"
LOG_AUDIT="$LOG_DIR/audit"
LOG_REMED="$LOG_DIR/remed"

HOSTNAME="$(hostname -s)"
DATE="$(date +%Y%m%d-%H%M%S)"

# ===============================
# Funções auxiliares
# ===============================

ensure_dirs() {
    mkdir -p "$LOG_AUDIT" "$LOG_REMED"
}

list_scripts() {
    local DIR="$1"
    mapfile -t scripts < <(ls "$DIR"/*.sh 2>/dev/null | sort -V)
    echo "${scripts[@]}"
}

run_scripts() {
    local DIR="$1"
    local LOGFILE="$2"

    echo "▶ Executando scripts em: $DIR" | tee -a "$LOGFILE"
    echo "" | tee -a "$LOGFILE"

    mapfile -t scripts < <(ls "$DIR"/*.sh 2>/dev/null | sort -V)

    if (( ${#scripts[@]} == 0 )); then
        echo "⚠️ Nenhum script encontrado em $DIR" | tee -a "$LOGFILE"
        return 1
    fi

    for shfile in "${scripts[@]}"; do
        local name="$(basename "$shfile")"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOGFILE"
        echo "[ $(date +%H:%M:%S) ] ▶ Rodando: $name" | tee -a "$LOGFILE"

        [[ -x "$shfile" ]] || chmod +x "$shfile"

        bash "$shfile" 2>&1 | tee -a "$LOGFILE"
        status=${PIPESTATUS[0]}

        if (( status == 0 )); then
            echo "✔ FINALIZADO: $name" | tee -a "$LOGFILE"
        else
            echo "❌ ERRO: $name (exit $status)" | tee -a "$LOGFILE"
        fi
        echo "" | tee -a "$LOGFILE"
    done
}

summary() {
    local LOG="$1"

    echo ""
    echo "=== RESUMO ==="
    local ok=$(grep -c "APROVADO" "$LOG")
    local fail=$(grep -c "REPROVADO" "$LOG")

    echo "✅ Aprovados : $ok"
    echo "❌ Reprovados: $fail"
    echo "📄 Log: $LOG"
}

# ===============================
# Execução principal
# ===============================

ensure_dirs

echo "=== HARDENING EXECUTOR — $HOSTNAME ==="
echo "1) Rodar AUDIT"
echo "2) Rodar REMEDIAÇÃO"
echo "3) Rodar AUDIT → REMEDIAÇÃO → AUDIT PÓS"
echo "q) Sair"
read -rp "Escolha: " OPT

case "$OPT" in
    1)
        LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
        echo "=== AUDIT PRE ===" | tee "$LOG_PRE"
        run_scripts "$AUDIT_DIR" "$LOG_PRE"
        summary "$LOG_PRE"
        ;;
    2)
        LOG_R="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
        echo "=== REMEDIAÇÃO ===" | tee "$LOG_R"
        run_scripts "$REMED_DIR" "$LOG_R"
        ;;
    3)
        LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
        LOG_R="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
        LOG_POST="$LOG_AUDIT/audit-post-${HOSTNAME}-${DATE}.log"

        echo "=== AUDIT PRE ===" | tee "$LOG_PRE"
        run_scripts "$AUDIT_DIR" "$LOG_PRE"

        echo ""
        echo "=== REMEDIAÇÃO ===" | tee "$LOG_R"
        run_scripts "$REMED_DIR" "$LOG_R"

        echo ""
        echo "=== AUDIT PÓS ===" | tee "$LOG_POST"
        run_scripts "$AUDIT_DIR" "$LOG_POST"

        echo ""
        echo "=== COMPARATIVO PRÉ x PÓS ==="
        pre_ok=$(grep -c "APROVADO" "$LOG_PRE")
        pre_fail=$(grep -c "REPROVADO" "$LOG_PRE")
        post_ok=$(grep -c "APROVADO" "$LOG_POST")
        post_fail=$(grep -c "REPROVADO" "$LOG_POST")

        echo "Antes:  ✅ $pre_ok | ❌ $pre_fail"
        echo "Depois: ✅ $post_ok | ❌ $post_fail"

        improvement=$((pre_fail - post_fail))
        if (( improvement > 0 )); then
            echo "✔ Melhorou $improvement controles"
        elif (( improvement == 0 )); then
            echo "⚠️ Nenhuma melhoria"
        else
            echo "❌ Regressão detectada"
        fi
        ;;
    q|Q)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida."
        ;;
esac
