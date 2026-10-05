#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIT_DIR="$BASE_DIR/AUDIT_SH"
REMED_DIR="$BASE_DIR/REMED_SH"
LOG_DIR="$BASE_DIR/logs"
LOG_AUDIT="$LOG_DIR/audit"
LOG_REMED="$LOG_DIR/remed"
HOSTNAME="$(hostname -s)"
DATE="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_AUDIT" "$LOG_REMED"
TOTAL_PASS=0
TOTAL_FAIL=0
########################################
# Contador (usado apenas no AUDIT)
########################################
count_results() {
    local content="$1"
    local p f
    p=$(grep -c -E '^[[:space:]]*PASS[[:space:]]*$' <<< "$content" || true)
    f=$(grep -c -E '^[[:space:]]*FAIL[[:space:]]*$' <<< "$content" || true)
    echo "$p $f"
}
########################################
# Coleta scripts com glob robusto
########################################
collect_scripts() {
    local DIR="$1"
    shopt -s nullglob
    local arr=("$DIR"/*.sh)
    shopt -u nullglob
    (( ${#arr[@]} > 0 )) || return 1
    IFS=$'\n' printf "%s\n" "${arr[@]}" | sort -V
}
########################################
# EXECUTOR AUDIT
########################################

run_audit_scripts() {
    local DIR="$1"
    local LOGFILE="$2"
    : > "$LOGFILE"

    mapfile -t scripts < <(collect_scripts "$DIR") || {
        echo "Nenhum script encontrado em $DIR"
        return 1
    }

    for shfile in "${scripts[@]}"; do
        local name current_id line
        name="$(basename "$shfile")"

        echo ">> $name"

        # captura saída completa do script
        output="$(bash "$shfile" 2>&1 | tee -a "$LOGFILE")"

        current_id=""

        # parser contextual
        while IFS= read -r line; do
            # captura ID: [12] Descrição
            if [[ "$line" =~ ^\[[0-9]+\] ]]; then
                current_id="$(sed -n 's/^\[\([0-9]\+\)\].*/\1/p' <<<"$line")"

            elif [[ "$line" == "PASS" && -n "$current_id" ]]; then
                TOTAL_PASS=$((TOTAL_PASS + 1))
                printf "%s,%s,APROVADO\n" "$HOSTNAME" "$current_id" >> "$LOG_AUDIT/audit-current.csv"

            elif [[ "$line" == "FAIL" && -n "$current_id" ]]; then
                TOTAL_FAIL=$((TOTAL_FAIL + 1))
                printf "%s,%s,REPROVADO\n" "$HOSTNAME" "$current_id" >> "$LOG_AUDIT/audit-current.csv"
            fi
        done <<< "$output"
    done
}
########################################
# EXECUTOR REMEDIAÇÃO
########################################
run_remed_scripts() {
    local DIR="$1"
    local LOGFILE="$2"
    : > "$LOGFILE"
    mapfile -t scripts < <(collect_scripts "$DIR") || {
        echo "Nenhum script encontrado em $DIR"
        return 1
    }
    for shfile in "${scripts[@]}"; do
        local name
        name="$(basename "$shfile")"
        bash "$shfile" >> "$LOGFILE" 2>&1 || true
        printf "%-30s OK\n" "$name"
    done
}
########################################
# RESUMO
########################################
summary() {
    local total percent
    total=$((TOTAL_PASS + TOTAL_FAIL))
    percent=0
    (( total > 0 )) && percent=$(( (TOTAL_PASS * 100) / total ))
    echo ""
    echo "Resumo:"
    echo "PASS : $TOTAL_PASS"
    echo "FAIL : $TOTAL_FAIL"
    echo "Aderência: ${percent}%"
}
########################################
# RELATÓRIO RÁPIDO: Itens não remediados
########################################
report_unfixed() {
    local last_post
    last_post=$(ls -1t "$LOG_AUDIT"/audit-post-* 2>/dev/null | head -n 1)
    if [[ -z "$last_post" ]]; then
        echo "Nenhum log audit-post encontrado."
        return 1
    fi
    echo "Último log: $last_post"
    echo ""
    echo "Itens sem remediação:"
    # pega linha acima do FAIL e remove o FAIL
    grep -a1 'FAIL' "$last_post" |
        sed 's/^[[:space:]]*//; /FAIL/d' |
        sed '/^--$/d'
}
########################################
# MODOS
########################################
run_audit() {
    TOTAL_PASS=0; TOTAL_FAIL=0

    # 🔽 GARANTE IDEMPOTÊNCIA DO CSV "CURRENT"
    printf "host,id,status\n" > "$LOG_AUDIT/audit-current.csv"

    LOG="$LOG_AUDIT/audit-${HOSTNAME}-${DATE}.log"
    echo "=== AUDIT ==="
    run_audit_scripts "$AUDIT_DIR" "$LOG"
    summary
    echo "Log: $LOG"
}
run_remed() {
    LOG="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
    echo "=== REMEDIAÇÃO ==="
    run_remed_scripts "$REMED_DIR" "$LOG"
    echo "Log: $LOG"
}
run_full() {
    LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
    LOG_R="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
    LOG_POST="$LOG_AUDIT/audit-post-${HOSTNAME}-${DATE}.log"
    echo "=== AUDIT PRÉ ==="
    TOTAL_PASS=0; TOTAL_FAIL=0
    run_audit_scripts "$AUDIT_DIR" "$LOG_PRE"
    pre_pass=$TOTAL_PASS
    pre_fail=$TOTAL_FAIL
    summary
    echo ""
    echo "=== REMEDIAÇÃO ==="
    run_remed_scripts "$REMED_DIR" "$LOG_R"
    echo ""
    echo "=== AUDIT PÓS ==="
    TOTAL_PASS=0; TOTAL_FAIL=0
    run_audit_scripts "$AUDIT_DIR" "$LOG_POST"
    post_pass=$TOTAL_PASS
    post_fail=$TOTAL_FAIL
    summary
    echo ""
    echo "Comparativo:"
    echo "Antes : PASS $pre_pass | FAIL $pre_fail"
    echo "Depois: PASS $post_pass | FAIL $post_fail"
    improvement=$((pre_fail - post_fail))
    if (( improvement > 0 )); then
        echo "Melhoria em $improvement controles"
    elif (( improvement == 0 )); then
        echo "Sem alteração"
    else
        echo "Regressão detectada"
    fi
    echo ""
    echo "Logs:"
    echo "PRE  : $LOG_PRE"
    echo "REMED: $LOG_R"
    echo "POST : $LOG_POST"
}
########################################
# ENTRADA
########################################
case "${1:-menu}" in
    audit)   run_audit ;;
    remed)   run_remed ;;
    full)    run_full ;;
    report)  report_unfixed ;;
    menu)
        echo "1) Audit"
        echo "2) Remediação"
        echo "3) Full (Audit → Remed → Audit)"
        echo "4) Itens não remediados (último audit-post)"
        read -rp "Escolha: " opt
        case "$opt" in
            1) run_audit ;;
            2) run_remed ;;
            3) run_full ;;
            4) report_unfixed ;;
            *) exit 1 ;;
        esac
        ;;
    *) exit 1 ;;
esac
