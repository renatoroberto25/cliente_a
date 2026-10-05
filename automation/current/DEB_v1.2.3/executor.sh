#!/usr/bin/env bash
set -euo pipefail

require_deblike() {
    [ -r /etc/os-release ] || { echo "ERRO: sistema DEB-like nao identificado." >&2; exit 2; }
    . /etc/os-release
    case "${ID:-} ${ID_LIKE:-}" in *debian*|*ubuntu*) ;; *) echo "ERRO: automacao exclusiva para Debian-like." >&2; exit 2 ;; esac
}

require_deblike

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR"
AUDIT_DIR="$BASE_DIR/AUDIT_SH"
if [ -d "$BASE_DIR/REMED_GROUPS" ]; then
    REMED_DIR="$BASE_DIR/REMED_GROUPS"
else
    REMED_DIR="$BASE_DIR/REMED_SH"
fi
LOG_DIR="$BASE_DIR/logs"
LOG_AUDIT="$LOG_DIR/audit"
LOG_REMED="$LOG_DIR/remed"
REPORT_DIR="$LOG_DIR/reports"
BACKUP_ROOT="${HITSS_BACKUP_ROOT:-/var/backups/hitss-hardening}"
HITSS_LOG_FILE="/var/log/hitss-hardening.log"
HITSS_VERSION="HARDENING HITSS DEB-like v1.0.3"
HITSS_ORIGIN="VIA EXECUCAO LOCAL AUTOMACAO SHELLSCRIPT"
HOSTNAME="$(hostname -s)"
DATE="$(date +%Y%m%d-%H%M%S)"
RUN_ID=""
RUN_DIR=""
PREFLIGHT_FILE=""
AUDIT_TECH_ERRORS=0
REMED_TECH_ERRORS=0

mkdir -p "$LOG_AUDIT" "$LOG_REMED" "$REPORT_DIR"

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_REMED_OK=0
TOTAL_REMED_WARN=0
TOTAL_REMED_SKIP=0
TOTAL_REMED_INFO=0
TOTAL_REMED_ERR=0

require_root() {
    if (( EUID != 0 )); then
        echo "ERRO: esta operacao exige execucao como root." >&2
        return 1
    fi
}

acquire_lock() {
    command -v flock >/dev/null 2>&1 || {
        echo "ERRO: flock e obrigatorio para remed, full e rollback." >&2
        return 1
    }
    exec 9> /run/lock/hitss-hardening-deb.lock
    if ! flock -n 9; then
        echo "ERRO: outra operacao de hardening DEB-like esta em execucao." >&2
        return 1
    fi
}

new_run() {
    DATE="$(date +%Y%m%d-%H%M%S)"
    RUN_ID="hitss-${HOSTNAME}-${DATE}-$$"
    RUN_DIR="$REPORT_DIR/$RUN_ID"
    PREFLIGHT_FILE="$RUN_DIR/precheck.csv"
    install -d -m 0700 "$RUN_DIR"
}

os_release() {
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        printf '%s\n' "${PRETTY_NAME:-${NAME:-Linux}}"
    elif [ -r /etc/debian_version ]; then
        printf 'Debian %s\n' "$(cat /etc/debian_version)"
    else
        uname -s
    fi
}

os_major() {
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        printf '%s\n' "${VERSION_ID%%.*}"
    elif [ -r /etc/debian_version ]; then
        cut -d. -f1 /etc/debian_version
    fi
}

hitss_stamp() {
    local action="$1"
    local status="$2"
    local logfile="${3:-}"
    local now os version

    now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    os="$(os_release)"
    version="$(os_major)"

    if [ "$(id -u)" -eq 0 ]; then
        touch "$HITSS_LOG_FILE"
        chmod 0600 "$HITSS_LOG_FILE"
        {
            printf '%s - %s - %s - %s - host: %s' "$now" "$action" "$HITSS_VERSION" "$HITSS_ORIGIN" "$HOSTNAME"
            printf ' - os: %s - version: %s - status: %s' "$os" "${version:-unknown}" "$status"
            [ -n "$logfile" ] && printf ' - logfile: %s' "$logfile"
            printf '\n'
        } >> "$HITSS_LOG_FILE"
    else
        echo "WARN: sem root, nao foi possivel escrever em $HITSS_LOG_FILE"
    fi
}

banner() {
    local title="$1"
    echo ""
    echo "============================================================"
    echo "$title"
    echo "Host : $HOSTNAME"
    echo "Data : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "SO   : $(os_release)"
    echo "============================================================"
}

need_root_warn() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "WARN: execute como root para resultados completos de audit/remed."
        echo ""
    fi
}

record_preflight() {
    local check="$1" severity="$2" result="$3" detail="$4"
    detail="${detail//\"/\"\"}"
    printf '%s,%s,%s,"%s"\n' "$check" "$severity" "$result" "$detail" >> "$PREFLIGHT_FILE"
    printf '%-22s %-8s %s\n' "$check" "$result" "$detail"
}

run_precheck() {
    local mode="${1:-audit}" failures=0 warnings=0 syntax_errors=0
    local major free_kb min_kb disk_path command script
    [ -n "$RUN_DIR" ] || new_run
    printf 'CHECK,SEVERITY,RESULT,DETAIL\n' > "$PREFLIGHT_FILE"
    banner "PRE-CHECK DEB-LIKE"

    record_preflight os_family BLOCK PASS "$(os_release)"
    major="$(os_major 2>/dev/null || true)"
    if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 11 )); then
        record_preflight os_version BLOCK PASS "major=$major"
    else
        record_preflight os_version BLOCK FAIL "versao minima suportada: 11; detectada=${major:-unknown}"
        failures=$((failures + 1))
    fi

    if [[ "$mode" == remed || "$mode" == full || "$mode" == rollback ]]; then
        if (( EUID == 0 )); then
            record_preflight root BLOCK PASS "execucao privilegiada"
        else
            record_preflight root BLOCK FAIL "operacao $mode exige root"
            failures=$((failures + 1))
        fi
    elif (( EUID == 0 )); then
        record_preflight root INFO PASS "audit com privilegios completos"
    else
        record_preflight root WARN WARN "audit sem root pode gerar falsos FAIL"
        warnings=$((warnings + 1))
    fi

    for script in "$BASE_DIR/executor.sh" "$AUDIT_DIR"/*.sh "$REMED_DIR"/*.sh; do
        [ -f "$script" ] || continue
        if ! bash -n "$script"; then
            record_preflight shell_syntax BLOCK FAIL "$script"
            failures=$((failures + 1))
            syntax_errors=$((syntax_errors + 1))
        fi
    done
    if (( syntax_errors == 0 )); then
        record_preflight shell_syntax BLOCK PASS "executor, audit e remediadores validos"
    fi

    for command in bash awk sed grep tar find stat systemctl dpkg-query apt-get flock; do
        if ! command -v "$command" >/dev/null 2>&1; then
            record_preflight "cmd_$command" BLOCK FAIL "comando obrigatorio ausente"
            failures=$((failures + 1))
        fi
    done

    disk_path="$(dirname "$BACKUP_ROOT")"
    [ -d "$disk_path" ] || disk_path=/
    min_kb="${HITSS_MIN_FREE_KB:-102400}"
    free_kb="$(df -Pk "$disk_path" | awk 'NR==2 {print $4}')"
    if [[ "$free_kb" =~ ^[0-9]+$ ]] && (( free_kb >= min_kb )); then
        record_preflight disk_free BLOCK PASS "${free_kb} KB livres"
    else
        record_preflight disk_free BLOCK FAIL "livre=${free_kb:-unknown} KB minimo=$min_kb KB"
        failures=$((failures + 1))
    fi

    if command -v sshd >/dev/null 2>&1 && [ -f /etc/ssh/sshd_config ]; then
        if sshd -t -f /etc/ssh/sshd_config >/dev/null 2>&1; then
            record_preflight sshd_config BLOCK PASS "configuracao atual valida"
        else
            record_preflight sshd_config BLOCK FAIL "sshd -t rejeitou a configuracao atual"
            failures=$((failures + 1))
        fi
    else
        record_preflight sshd_config INFO SKIP "sshd nao instalado"
    fi

    if command -v visudo >/dev/null 2>&1; then
        if visudo -cf /etc/sudoers >/dev/null 2>&1; then
            record_preflight sudoers BLOCK PASS "configuracao atual valida"
        else
            record_preflight sudoers BLOCK FAIL "visudo rejeitou a configuracao atual"
            failures=$((failures + 1))
        fi
    else
        record_preflight sudoers INFO SKIP "sudo nao instalado"
    fi

    if (( failures > 0 )); then
        echo "PRE-CHECK: FAIL ($failures bloqueio(s), $warnings aviso(s))"
        return 2
    fi
    echo "PRE-CHECK: PASS ($warnings aviso(s))"
}

count_results() {
    local content="$1"
    local p f
    p=$(grep -c -E ',PASS[[:space:]]*$' <<< "$content" || true)
    f=$(grep -c -E ',FAIL[[:space:]]*$' <<< "$content" || true)
    echo "$p $f"
}

count_words() {
    local word="$1"
    local content="$2"
    grep -c -E "^[[:space:]]*${word}:" <<< "$content" || true
}

collect_scripts() {
    local DIR="$1"
    shopt -s nullglob
    local arr=("$DIR"/*.sh)
    shopt -u nullglob
    (( ${#arr[@]} > 0 )) || return 1
    printf "%s\n" "${arr[@]}" | sort -V
}

run_audit_scripts() {
    local DIR="$1"
    local LOGFILE="$2"
    local -a scripts=()
    : > "$LOGFILE"
    mapfile -t scripts < <(collect_scripts "$DIR")
    if (( ${#scripts[@]} == 0 )); then
        echo "Nenhum script encontrado em $DIR"
        return 1
    fi
    for shfile in "${scripts[@]}"; do
        local name output p f rc
        name="$(basename "$shfile")"
        {
            echo ""
            echo "### $name"
        } >> "$LOGFILE"

        set +e
        output="$(bash "$shfile" 2>&1 | tee -a "$LOGFILE")"
        rc=$?
        set -e

        read p f <<< "$(count_results "$output")"
        TOTAL_PASS=$((TOTAL_PASS + p))
        TOTAL_FAIL=$((TOTAL_FAIL + f))
        if [ "$rc" -eq 0 ]; then
            printf "%-30s PASS(%-3s) FAIL(%-3s)\n" "$name" "$p" "$f"
        else
            AUDIT_TECH_ERRORS=$((AUDIT_TECH_ERRORS + 1))
            printf "%-30s PASS(%-3s) FAIL(%-3s) RC(%s)\n" "$name" "$p" "$f" "$rc"
        fi
    done
}

run_remed_scripts() {
    local DIR="$1"
    local LOGFILE="$2"
    local -a scripts=()
    : > "$LOGFILE"
    mapfile -t scripts < <(collect_scripts "$DIR")
    if (( ${#scripts[@]} == 0 )); then
        echo "Nenhum script encontrado em $DIR"
        return 1
    fi
    for shfile in "${scripts[@]}"; do
        local name output rc ok warn skip info
        name="$(basename "$shfile")"
        {
            echo ""
            echo "### $name"
        } >> "$LOGFILE"

        set +e
        output="$(bash "$shfile" 2>&1)"
        rc=$?
        set -e

        printf "%s\n" "$output" >> "$LOGFILE"
        ok="$(count_words OK "$output")"
        warn="$(count_words WARN "$output")"
        skip="$(count_words SKIP "$output")"
        info="$(count_words INFO "$output")"

        TOTAL_REMED_OK=$((TOTAL_REMED_OK + ok))
        TOTAL_REMED_WARN=$((TOTAL_REMED_WARN + warn))
        TOTAL_REMED_SKIP=$((TOTAL_REMED_SKIP + skip))
        TOTAL_REMED_INFO=$((TOTAL_REMED_INFO + info))
        if [ "$rc" -ne 0 ]; then
            TOTAL_REMED_ERR=$((TOTAL_REMED_ERR + 1))
            REMED_TECH_ERRORS=$((REMED_TECH_ERRORS + 1))
        fi

        printf "%-30s OK(%-3s) WARN(%-3s) SKIP(%-3s) INFO(%-3s) RC(%s)\n" \
            "$name" "$ok" "$warn" "$skip" "$info" "$rc"
    done
}

generate_comparison() {
    local pre="$1" post="$2" output="$RUN_DIR/comparison.csv"
    awk -F, '
        function quote(s) { gsub(/"/, "\"\"", s); return "\"" s "\"" }
        FNR==NR {
            if ($1 ~ /^[0-9]+$/ && $4 ~ /^(PASS|FAIL)$/) {
                before[$1]=$4; name[$1]=$2; severity[$1]=$3
            }
            next
        }
        $1 ~ /^[0-9]+$/ && $4 ~ /^(PASS|FAIL)$/ {
            after[$1]=$4
            if (!($1 in name)) { name[$1]=$2; severity[$1]=$3 }
        }
        END {
            print "ID,NOME,CRITICIDADE,ANTES,DEPOIS,TRANSICAO"
            for (id in name) {
                pre=(id in before ? before[id] : "MISSING")
                post=(id in after ? after[id] : "MISSING")
                if (pre=="FAIL" && post=="PASS") transition="FIXED"
                else if (pre=="PASS" && post=="FAIL") transition="REGRESSION"
                else if (pre==post) transition="UNCHANGED"
                else transition="ERROR"
                rows[id]=id "," quote(name[id]) "," quote(severity[id]) "," pre "," post "," transition
            }
            for (i=0; i<=9999; i++) if (i in rows) print rows[i]
        }
    ' "$pre" "$post" > "$output"
}

generate_summary() {
    local pre="$1" post="$2" fixed regressions missing status output
    generate_comparison "$pre" "$post"
    fixed="$(awk -F, '$6=="FIXED" {n++} END {print n+0}' "$RUN_DIR/comparison.csv")"
    regressions="$(awk -F, '$6=="REGRESSION" {n++} END {print n+0}' "$RUN_DIR/comparison.csv")"
    missing="$(awk -F, '$6=="ERROR" {n++} END {print n+0}' "$RUN_DIR/comparison.csv")"
    status=SUCCESS
    if (( post_fail > 0 )); then
        status=PARTIAL
    fi
    if (( regressions > 0 || missing > 0 || AUDIT_TECH_ERRORS > 0 || REMED_TECH_ERRORS > 0 )); then
        status=FAILED
    fi
    output="$RUN_DIR/summary.csv"
    printf 'RUN_ID,HOST,VERSION,STATUS,PRE_PASS,PRE_FAIL,POST_PASS,POST_FAIL,FIXED,REGRESSIONS,MISSING,REMED_OK,REMED_WARN,REMED_SKIP,REMED_INFO,REMED_ERROR,AUDIT_ERROR,BACKUP_ID\n' > "$output"
    printf '%s,%s,"%s",%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$RUN_ID" "$HOSTNAME" "$HITSS_VERSION" "$status" "$pre_pass" "$pre_fail" "$post_pass" "$post_fail" \
        "$fixed" "$regressions" "$missing" "$TOTAL_REMED_OK" "$TOTAL_REMED_WARN" "$TOTAL_REMED_SKIP" \
        "$TOTAL_REMED_INFO" "$REMED_TECH_ERRORS" "$AUDIT_TECH_ERRORS" "${HITSS_BACKUP_ID:-}" >> "$output"
    printf '%s\n' "$status"
}

prepare_backup_session() {
    local session_date suffix=0
    session_date="$(date +%Y%m%d-%H%M%S)"
    HITSS_BACKUP_ID="hitss_hardening_bkp_${session_date}"
    while [[ -e "$BACKUP_ROOT/$HITSS_BACKUP_ID" ]]; do
        suffix=$((suffix + 1))
        HITSS_BACKUP_ID="hitss_hardening_bkp_${session_date}-$(printf '%02d' "$suffix")"
    done
    HITSS_BACKUP_DIR="$BACKUP_ROOT/$HITSS_BACKUP_ID"
    HITSS_BACKUP_MANIFEST="$HITSS_BACKUP_DIR/manifest.tsv"
    if [ "$(id -u)" -eq 0 ]; then
        install -d -m 0700 "$HITSS_BACKUP_DIR"
        : > "$HITSS_BACKUP_MANIFEST"
        chmod 0600 "$HITSS_BACKUP_MANIFEST"
        {
            printf 'id=%s\n' "$HITSS_BACKUP_ID"
            printf 'created=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
            printf 'host=%s\n' "$HOSTNAME"
            printf 'status=in_progress\n'
        } > "$HITSS_BACKUP_DIR/session.info"
    fi
    export TS="$session_date" HITSS_BACKUP_ROOT="$BACKUP_ROOT" HITSS_BACKUP_ID HITSS_BACKUP_DIR HITSS_BACKUP_MANIFEST
}

finish_backup_session() {
    [ -d "${HITSS_BACKUP_DIR:-}" ] || return 0
    sed -i 's/^status=.*/status=complete/' "$HITSS_BACKUP_DIR/session.info"
    echo "Backup da execucao: $HITSS_BACKUP_DIR"
    echo "Rollback: $0 rollback $HITSS_BACKUP_ID"
}

list_backups() {
    local dir status created
    echo "Backups disponiveis em $BACKUP_ROOT:"
    shopt -s nullglob
    for dir in "$BACKUP_ROOT"/hitss_hardening_bkp_*; do
        status="$(awk -F= '$1=="status" {print $2}' "$dir/session.info" 2>/dev/null || true)"
        created="$(awk -F= '$1=="created" {print $2}' "$dir/session.info" 2>/dev/null || true)"
        printf '%-42s  %-12s  %s\n' "$(basename "$dir")" "${status:-unknown}" "${created:-unknown}"
    done
    shopt -u nullglob
}

resolve_backup_dir() {
    local requested="${1:-latest}" candidate
    if [[ "$requested" == latest ]]; then
        candidate="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name 'hitss_hardening_bkp_*' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)"
    elif [[ "$requested" == hitss_hardening_bkp_* && "$requested" != */* ]]; then
        candidate="$BACKUP_ROOT/$requested"
    else
        echo "ERRO: identificador de backup invalido: $requested" >&2
        return 1
    fi
    [[ -n "$candidate" && -d "$candidate" && -f "$candidate/manifest.tsv" ]] || {
        echo "ERRO: backup nao encontrado: $requested" >&2; return 1;
    }
    printf '%s\n' "$candidate"
}

rollback_session() {
    local backup_dir manifest type target data mode uid gid enabled active masked rc=0
    (( EUID == 0 )) || { echo "ERRO: rollback deve ser executado como root." >&2; return 1; }
    acquire_lock
    backup_dir="$(resolve_backup_dir "${1:-latest}")" || return 1
    manifest="$backup_dir/manifest.tsv"
    banner "ROLLBACK $(basename "$backup_dir")"
    while IFS=$'\t' read -r type target data; do
        case "$type" in
            FILE)
                if [[ "$data" == ABSENT ]]; then
                    if [[ -d "$target" && ! -L "$target" ]]; then
                        rmdir -- "$target" 2>/dev/null || { echo "WARN: diretorio criado nao esta vazio: $target"; rc=1; }
                    elif [[ -e "$target" || -L "$target" ]]; then
                        rm -f -- "$target" || rc=1
                    fi
                    (( rc == 0 )) && echo "OK: estado ausente restaurado: $target"
                elif [[ -e "$backup_dir/files$target" || -L "$backup_dir/files$target" ]]; then
                    rm -f -- "$target" 2>/dev/null || true
                    install -d -m 0755 "$(dirname "$target")"
                    cp -a -- "$backup_dir/files$target" "$target" && echo "OK: restaurado $target" || rc=1
                else
                    echo "WARN: copia ausente para $target"; rc=1
                fi
                ;;
            META)
                IFS=: read -r mode uid gid <<< "$data"
                if [[ -e "$target" || -L "$target" ]]; then
                    chown "$uid:$gid" -- "$target" && chmod "$mode" -- "$target" && echo "OK: metadados restaurados: $target" || rc=1
                fi
                ;;
            SYSCTL)
                sysctl -w "$target=$data" >/dev/null 2>&1 && echo "OK: sysctl restaurado: $target=$data" || { echo "WARN: sysctl $target"; rc=1; }
                ;;
            UNIT)
                IFS='|' read -r enabled active masked <<< "$data"
                if (( masked == 0 )); then systemctl unmask "$target" >/dev/null 2>&1 || true; fi
                if [[ "$enabled" == enabled* ]]; then
                    systemctl enable "$target" >/dev/null 2>&1 || rc=1
                else
                    systemctl disable "$target" >/dev/null 2>&1 || true
                fi
                if [[ "$active" == active ]]; then
                    systemctl start "$target" >/dev/null 2>&1 || rc=1
                else
                    systemctl stop "$target" >/dev/null 2>&1 || true
                fi
                if (( masked == 1 )); then systemctl mask "$target" >/dev/null 2>&1 || rc=1; fi
                echo "OK: estado da unidade restaurado: $target"
                ;;
            PACKAGES)
                # shellcheck disable=SC2086
                DEBIAN_FRONTEND=noninteractive apt-get install -y $data >/dev/null 2>&1 && echo "OK: pacotes reinstalados: $data" || { echo "WARN: falha ao reinstalar: $data"; rc=1; }
                ;;
        esac
    done < <(tac "$manifest")
    if grep -Fq $'FILE\t/etc/ssh/' "$manifest" && command -v sshd >/dev/null && sshd -t; then
        systemctl reload ssh.service >/dev/null 2>&1 || systemctl reload sshd.service >/dev/null 2>&1 || true
    fi
    if grep -Fq $'FILE\t/etc/systemd/journald.conf\t' "$manifest"; then
        systemctl restart systemd-journald.service >/dev/null 2>&1 || rc=1
    fi
    if grep -Fq $'FILE\t/etc/audit/' "$manifest" && command -v augenrules >/dev/null; then
        augenrules --load >/dev/null 2>&1 || { echo "WARN: regras auditd exigem reboot para restauracao ativa"; rc=1; }
    fi
    if (( rc == 0 )); then
        sed -i 's/^status=.*/status=rolled_back/' "$backup_dir/session.info"
        hitss_stamp "ROLLBACK" "END backup=$(basename "$backup_dir")" "$manifest"
        echo "Rollback concluido. Manifesto: $manifest"
    else
        echo "Rollback concluido com avisos. Consulte: $manifest"
    fi
    return "$rc"
}

summary() {
    local total percent
    total=$((TOTAL_PASS + TOTAL_FAIL))
    percent=0
    (( total > 0 )) && percent=$(( (TOTAL_PASS * 100) / total ))
    echo ""
    echo "Resumo:"
    echo "TOTAL: $total"
    echo "PASS : $TOTAL_PASS"
    echo "FAIL : $TOTAL_FAIL"
    echo "Aderencia: ${percent}%"
}

summary_remed() {
    echo ""
    echo "Resumo remediacao:"
    echo "OK   : $TOTAL_REMED_OK"
    echo "WARN : $TOTAL_REMED_WARN"
    echo "SKIP : $TOTAL_REMED_SKIP"
    echo "INFO : $TOTAL_REMED_INFO"
    echo "ERRO : $TOTAL_REMED_ERR"
}

print_failed_items() {
    local logfile="$1"
    awk -F, '$4 == "FAIL" { print $1 "," $2 "," $3 }' "$logfile"
}

latest_audit_log() {
    { ls -1t "$LOG_AUDIT"/audit-post-* "$LOG_AUDIT"/audit-* 2>/dev/null || true; } | head -n 1
}

report_unfixed() {
    local last_log
    last_log="$(latest_audit_log)"
    if [[ -z "$last_log" ]]; then
        echo "Nenhum log de audit encontrado."
        return 1
    fi
    echo "Ultimo log: $last_log"
    echo ""
    echo "Itens em FAIL:"
    print_failed_items "$last_log"
}

run_status() {
    local last_log p f total percent
    last_log="$(latest_audit_log)"
    if [[ -z "$last_log" ]]; then
        echo "Nenhum log de audit encontrado."
        return 1
    fi
    read p f <<< "$(count_results "$(cat "$last_log")")"
    total=$((p + f))
    percent=0
    (( total > 0 )) && percent=$(( (p * 100) / total ))
    echo "Ultimo audit: $last_log"
    echo "PASS: $p | FAIL: $f | Aderencia: ${percent}%"
    echo ""
    echo "Top FAIL:"
    print_failed_items "$last_log" | head -n 20
}

run_audit() {
    new_run
    run_precheck audit || return $?
    TOTAL_PASS=0; TOTAL_FAIL=0
    AUDIT_TECH_ERRORS=0
    LOG="$LOG_AUDIT/audit-${HOSTNAME}-${DATE}.log"
    need_root_warn
    hitss_stamp "AUDIT" "START" "$LOG"
    banner "AUDIT"
    run_audit_scripts "$AUDIT_DIR" "$LOG"
    summary
    hitss_stamp "AUDIT" "END pass=$TOTAL_PASS fail=$TOTAL_FAIL" "$LOG"
    echo "Log: $LOG"
    echo "Pre-check: $PREFLIGHT_FILE"
    (( AUDIT_TECH_ERRORS == 0 ))
}

run_remed() {
    new_run
    run_precheck remed || return $?
    require_root
    acquire_lock
    TOTAL_REMED_OK=0; TOTAL_REMED_WARN=0; TOTAL_REMED_SKIP=0; TOTAL_REMED_INFO=0; TOTAL_REMED_ERR=0
    REMED_TECH_ERRORS=0
    LOG="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
    need_root_warn
    prepare_backup_session
    hitss_stamp "REMEDIATION" "START" "$LOG"
    banner "REMEDIACAO"
    run_remed_scripts "$REMED_DIR" "$LOG"
    finish_backup_session
    summary_remed
    hitss_stamp "REMEDIATION" "END ok=$TOTAL_REMED_OK warn=$TOTAL_REMED_WARN skip=$TOTAL_REMED_SKIP info=$TOTAL_REMED_INFO err=$TOTAL_REMED_ERR" "$LOG"
    echo "Log: $LOG"
    echo "Pre-check: $PREFLIGHT_FILE"
    (( REMED_TECH_ERRORS == 0 ))
}

run_full() {
    local final_status
    new_run
    run_precheck full || return $?
    require_root
    acquire_lock
    LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
    LOG_R="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
    LOG_POST="$LOG_AUDIT/audit-post-${HOSTNAME}-${DATE}.log"
    need_root_warn
    AUDIT_TECH_ERRORS=0
    REMED_TECH_ERRORS=0
    hitss_stamp "FULL" "START" "$LOG_PRE"
    banner "AUDIT PRE"
    TOTAL_PASS=0; TOTAL_FAIL=0
    run_audit_scripts "$AUDIT_DIR" "$LOG_PRE"
    pre_pass=$TOTAL_PASS
    pre_fail=$TOTAL_FAIL
    summary
    hitss_stamp "AUDIT" "END pre_pass=$pre_pass pre_fail=$pre_fail" "$LOG_PRE"
    echo ""
    banner "REMEDIACAO"
    prepare_backup_session
    TOTAL_REMED_OK=0; TOTAL_REMED_WARN=0; TOTAL_REMED_SKIP=0; TOTAL_REMED_INFO=0; TOTAL_REMED_ERR=0
    hitss_stamp "REMEDIATION" "START" "$LOG_R"
    run_remed_scripts "$REMED_DIR" "$LOG_R"
    finish_backup_session
    summary_remed
    hitss_stamp "REMEDIATION" "END ok=$TOTAL_REMED_OK warn=$TOTAL_REMED_WARN skip=$TOTAL_REMED_SKIP info=$TOTAL_REMED_INFO err=$TOTAL_REMED_ERR" "$LOG_R"
    echo ""
    banner "AUDIT POS"
    TOTAL_PASS=0; TOTAL_FAIL=0
    run_audit_scripts "$AUDIT_DIR" "$LOG_POST"
    post_pass=$TOTAL_PASS
    post_fail=$TOTAL_FAIL
    summary
    hitss_stamp "AUDIT" "END post_pass=$post_pass post_fail=$post_fail" "$LOG_POST"
    hitss_stamp "FULL" "END pre_fail=$pre_fail post_fail=$post_fail" "$LOG_POST"
    echo ""
    echo "Comparativo:"
    echo "Antes : PASS $pre_pass | FAIL $pre_fail"
    echo "Depois: PASS $post_pass | FAIL $post_fail"
    improvement=$((pre_fail - post_fail))
    if (( improvement > 0 )); then
        echo "Melhoria em $improvement controles"
    elif (( improvement == 0 )); then
        echo "Sem alteracao"
    else
        echo "Regressao detectada"
    fi
    echo ""
    echo "FAIL restantes:"
    print_failed_items "$LOG_POST" | head -n 30
    echo ""
    echo "Logs:"
    echo "PRE  : $LOG_PRE"
    echo "REMED: $LOG_R"
    echo "POST : $LOG_POST"
    final_status="$(generate_summary "$LOG_PRE" "$LOG_POST")"
    echo "REPORT: $RUN_DIR"
    echo "STATUS: $final_status"
    hitss_stamp "FULL" "REPORT status=$final_status run_id=$RUN_ID" "$RUN_DIR/summary.csv"
    [[ "$final_status" != FAILED ]] || return 4
}

run_precheck_only() {
    new_run
    run_precheck "${1:-full}"
    echo "Relatorio: $PREFLIGHT_FILE"
}

run_menu() {
    local opt
    while true; do
        echo ""
        echo "============================================================"
        echo "HARDENING - MENU"
        echo "============================================================"
        echo "1) Audit"
        echo "2) Pre-check operacional"
        echo "3) Remediacao"
        echo "4) Full (Pre-check -> Audit -> Remed -> Audit -> Report)"
        echo "5) Itens em FAIL (ultimo audit)"
        echo "6) Status do ultimo audit"
        echo "7) Listar backups"
        echo "8) Rollback do ultimo backup"
        echo "0) Sair"
        echo ""
        read -rp "Escolha: " opt
        case "$opt" in
            1) run_audit || echo "Operacao concluida com status $?." ;;
            2) run_precheck_only full || echo "Pre-check bloqueou a operacao (status $?)." ;;
            3) run_remed || echo "Remediacao concluida com status $?." ;;
            4) run_full || echo "Execucao full concluida com status $?." ;;
            5) report_unfixed || true ;;
            6) run_status || true ;;
            7) list_backups ;;
            8) rollback_session latest || echo "Rollback concluido com status $?." ;;
            0|q|Q|sair|exit) break ;;
            *) echo "Opcao invalida." ;;
        esac
        echo ""
        read -rp "Pressione ENTER para voltar ao menu..." _
    done
}

case "${1:-menu}" in
    audit)   run_audit ;;
    precheck) run_precheck_only "${2:-full}" ;;
    remed)   run_remed ;;
    full)    run_full ;;
    report)  report_unfixed ;;
    status)  run_status ;;
    backups) list_backups ;;
    rollback) rollback_session "${2:-latest}" ;;
    menu)    run_menu ;;
    *)
        echo "Uso: $0 {precheck [audit|remed|full]|audit|remed|full|report|status|backups|rollback [ID|latest]|menu}"
        exit 1
        ;;
esac
