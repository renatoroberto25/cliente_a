#!/usr/bin/env bash
# executor.sh - Auditoria e Remediação Hardening Light (resiliente)
# Estrutura esperada: {audit, remed, logs}

BASE_DIR="$(dirname "$(realpath "$0")")"
AUDIT_DIR="$BASE_DIR/audit"
REMED_DIR="$BASE_DIR/remed"
LOG_AUDIT="$BASE_DIR/logs/audit"
LOG_REMED="$BASE_DIR/logs/remed"

HOSTNAME=$(hostname -s)
DATE=$(date +%Y%m%d-%H%M%S)

# ===============================
# Funções auxiliares
# ===============================
check_tools() {
    for tool in bash grep tee sort; do
        command -v "$tool" >/dev/null || {
            echo "❌ Ferramenta '$tool' não encontrada. Instale antes de continuar."
            exit 1
        }
    done
}

check_dirs() {
    for dir in "$AUDIT_DIR" "$REMED_DIR"; do
        [[ -d "$dir" ]] || echo "⚠️ Diretório ausente: $dir"
    done
    mkdir -p "$LOG_AUDIT" "$LOG_REMED"
}

run_scripts() {
    local DIR="$1"
    local LOG="$2"

    echo "▶ Executando scripts em: $DIR"
    if [[ ! -d "$DIR" ]]; then
        echo "❌ Diretório não existe: $DIR" | tee -a "$LOG"
        return 1
    fi

    shopt -s nullglob
    local scripts=("$DIR"/*.sh)
    shopt -u nullglob

    if (( ${#scripts[@]} == 0 )); then
        echo "⚠️ Nenhum script encontrado em $DIR" | tee -a "$LOG"
        return 1
    fi

    for shfile in "${scripts[@]}"; do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG"
        echo "▶ Rodando: $(basename "$shfile")" | tee -a "$LOG"
        if bash "$shfile" 2>&1 | tee -a "$LOG"; then
            echo "✔ OK: $(basename "$shfile")" | tee -a "$LOG"
        else
            echo "❌ FAIL: $(basename "$shfile")" | tee -a "$LOG"
        fi
        echo "" | tee -a "$LOG"
    done
    echo "✔ Concluído, log salvo em: $LOG"
}

show_summary() {
    local LOG="$1"
    [[ -f "$LOG" ]] || { echo "⚠️ Log não encontrado: $LOG"; return; }
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
check_tools
check_dirs

echo "=== HARDENING LIGHT - $HOSTNAME ==="
echo "1) Auditoria pré"
echo "2) Remediações"
echo "3) Auditoria + Remediações + Auditoria pós"
echo "q) Sair"
read -rp "Escolha: " OPT

case "$OPT" in
    1)
        LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
        echo "=== AUDIT PRE ===" | tee "$LOG_PRE"
        run_scripts "$AUDIT_DIR" "$LOG_PRE"
        show_summary "$LOG_PRE"
        ;;
    2)
        LOG_REMED_FILE="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
        echo "=== REMEDIAÇÕES ===" | tee "$LOG_REMED_FILE"
        run_scripts "$REMED_DIR" "$LOG_REMED_FILE"
        ;;
    3)
        LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
        LOG_REMED_FILE="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
        LOG_POST="$LOG_AUDIT/audit-post-${HOSTNAME}-${DATE}.log"

        echo "=== AUDIT PRE ===" | tee "$LOG_PRE"
        run_scripts "$AUDIT_DIR" "$LOG_PRE"

        echo "=== REMEDIAÇÕES ===" | tee "$LOG_REMED_FILE"
        run_scripts "$REMED_DIR" "$LOG_REMED_FILE"

        echo "=== AUDIT PÓS ===" | tee "$LOG_POST"
        run_scripts "$AUDIT_DIR" "$LOG_POST"

        # Comparativo
        if [[ -f "$LOG_PRE" && -f "$LOG_POST" ]]; then
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
                echo "✔ Melhorou em $improvement controles"
            elif (( improvement == 0 )); then
                echo "⚠️ Nenhuma melhoria detectada"
            else
                echo "❌ Regressão detectada"
            fi
        fi
        ;;
    q|Q) echo "Saindo..." ;;
    *) echo "Opção inválida." ;;
esac