#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/AUDIT_SH" ]; then
    BASE_DIR="$SCRIPT_DIR"
else
    BASE_DIR="$SCRIPT_DIR/HARDENING_SHELLSCRIPTING/HARDENING_SHELLSCRIPT_RHEL8_9_FULL"
fi
AUDIT_DIR="$BASE_DIR/AUDIT_SH"
if [ -d "$BASE_DIR/REMED_GROUPS" ]; then
    REMED_DIR="$BASE_DIR/REMED_GROUPS"
else
    REMED_DIR="$BASE_DIR/REMED_SH"
fi
LOG_DIR="$BASE_DIR/logs"
LOG_AUDIT="$LOG_DIR/audit"
LOG_REMED="$LOG_DIR/remed"
BACKUP_DIR="$LOG_DIR/backups"
HITSS_LOG_FILE="/var/log/hitss-hardening.log"
HITSS_VERSION="HARDENING HITSS v1.3.5"
HITSS_ORIGIN="VIA EXECUCAO LOCAL AUTOMACAO SHELLSCRIPT"
HITSS_FAMILY="RHEL7_8_9"
HOSTNAME="$(hostname -s)"
DATE="$(date +%Y%m%d-%H%M%S-%N)"

mkdir -p "$LOG_AUDIT" "$LOG_REMED" "$BACKUP_DIR"

MANAGED_FILES=(
    /etc/modprobe.d/99-hitss-hardening.conf
    /etc/modprobe.d/99-hitss-wireless.conf
    /etc/sysctl.d/99-hitss-hardening.conf
    /etc/sysctl.d/99-hitss-network.conf
    /etc/security/limits.d/99-hitss-coredump.conf
    /etc/fstab
    /boot/grub2/grub.cfg
    /etc/cron.allow
    /etc/at.allow
    /etc/yum.conf
    /etc/dnf/dnf.conf
    /etc/ssh/sshd_config
    /etc/security/pwquality.conf
    /etc/security/faillock.conf
    /etc/login.defs
    /etc/pam.d/system-auth
    /etc/pam.d/password-auth
    /etc/pam.d/su
    /etc/shells
    /root/.bash_profile
    /etc/profile
    /etc/bashrc
    /etc/profile.d/99-hitss-umask.sh
    /etc/profile.d/99-hitss-tmout.sh
    /etc/sudoers
    /etc/sudoers.d/99-hitss-hardening
    /etc/systemd/journald.conf
    /etc/logrotate.conf
    /etc/logrotate.d/rsyslog
    /etc/audit/auditd.conf
    /etc/audit/rules.d/99-hitss-hardening.rules
    /etc/passwd
    /etc/passwd-
    /etc/shadow
    /etc/shadow-
    /etc/group
    /etc/group-
    /etc/gshadow
    /etc/gshadow-
    /etc/security/opasswd
)

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_REMED_OK=0
TOTAL_REMED_WARN=0
TOTAL_REMED_SKIP=0
TOTAL_REMED_INFO=0
TOTAL_REMED_ERR=0

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
            printf ' - os: %s - version: %s - family: %s - status: %s' "$os" "${version:-unknown}" "$HITSS_FAMILY" "$status"
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

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERRO: remediacao exige execucao como root." >&2
        return 1
    fi
}

acquire_remed_lock() {
    command -v flock >/dev/null 2>&1 || return 0
    exec 9> /run/lock/hitss-hardening.lock
    if ! flock -n 9; then
        echo "ERRO: outra remediacao HITSS esta em execucao." >&2
        return 1
    fi
}

create_snapshot() {
    local snapshot="$BACKUP_DIR/hitss-${HOSTNAME}-${DATE}"
    local present="${snapshot}.present" absent="${snapshot}.absent"
    local archive="${snapshot}.tar.gz" file repo

    : > "$present"
    : > "$absent"
    for file in "${MANAGED_FILES[@]}"; do
        if [ -e "$file" ] || [ -L "$file" ]; then
            printf '%s\n' "${file#/}" >> "$present"
        else
            printf '%s\n' "$file" >> "$absent"
        fi
    done
    for repo in /etc/yum.repos.d/*.repo; do
        [ -e "$repo" ] && printf '%s\n' "${repo#/}" >> "$present"
    done

    if tar -C / -czf "$archive" -T "$present"; then
        chmod 0600 "$archive" "$present" "$absent"
        LAST_SNAPSHOT="$archive"
        echo "Snapshot: $archive"
    else
        rm -f "$archive" "$present" "$absent"
        echo "ERRO: nao foi possivel criar snapshot; remediacao cancelada." >&2
        return 1
    fi
}

latest_snapshot() {
    ls -1t "$BACKUP_DIR"/hitss-*.tar.gz 2>/dev/null | head -n 1
}

run_rollback() {
    local archive="${1:-}" base absent file
    require_root
    acquire_remed_lock

    if [ -n "$archive" ] && [[ "$archive" != /* ]]; then
        archive="$BASE_DIR/$archive"
    fi
    [ -n "$archive" ] || archive="$(latest_snapshot)"
    if [ -z "$archive" ] || [ ! -f "$archive" ]; then
        echo "ERRO: snapshot nao encontrado: ${archive:-nenhum}" >&2
        return 1
    fi
    case "$archive" in
        "$BACKUP_DIR"/hitss-*.tar.gz) ;;
        *) echo "ERRO: o snapshot deve pertencer a $BACKUP_DIR" >&2; return 1 ;;
    esac

    base="${archive%.tar.gz}"
    absent="${base}.absent"
    [ -f "$absent" ] || {
        echo "ERRO: manifesto de rollback ausente: $absent" >&2
        return 1
    }

    tar -tzf "$archive" >/dev/null
    tar -C / -xzf "$archive"
    while IFS= read -r file; do
        case "$file" in
            /etc/*|/boot/grub2/grub.cfg|/root/.bash_profile) rm -f -- "$file" ;;
            *) echo "WARN: caminho recusado no manifesto: $file" ;;
        esac
    done < "$absent"
    echo "OK: rollback restaurado de $archive"
    echo "INFO: reinicie/recarregue os servicos afetados em janela controlada"
    hitss_stamp "ROLLBACK" "END snapshot=$archive" "$archive"
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
        [ "$rc" -ne 0 ] && TOTAL_REMED_ERR=$((TOTAL_REMED_ERR + 1))

        printf "%-30s OK(%-3s) WARN(%-3s) SKIP(%-3s) INFO(%-3s) RC(%s)\n" \
            "$name" "$ok" "$warn" "$skip" "$info" "$rc"
    done
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
    DATE="$(date +%Y%m%d-%H%M%S-%N)"
    TOTAL_PASS=0; TOTAL_FAIL=0
    LOG="$LOG_AUDIT/audit-${HOSTNAME}-${DATE}.log"
    need_root_warn
    hitss_stamp "AUDIT" "START" "$LOG"
    banner "AUDIT"
    run_audit_scripts "$AUDIT_DIR" "$LOG"
    summary
    hitss_stamp "AUDIT" "END pass=$TOTAL_PASS fail=$TOTAL_FAIL" "$LOG"
    echo "Log: $LOG"
}

run_remed() {
    require_root
    acquire_remed_lock
    DATE="$(date +%Y%m%d-%H%M%S-%N)"
    create_snapshot
    TOTAL_REMED_OK=0; TOTAL_REMED_WARN=0; TOTAL_REMED_SKIP=0; TOTAL_REMED_INFO=0; TOTAL_REMED_ERR=0
    LOG="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
    need_root_warn
    hitss_stamp "REMEDIATION" "START" "$LOG"
    banner "REMEDIACAO"
    run_remed_scripts "$REMED_DIR" "$LOG"
    summary_remed
    hitss_stamp "REMEDIATION" "END ok=$TOTAL_REMED_OK warn=$TOTAL_REMED_WARN skip=$TOTAL_REMED_SKIP info=$TOTAL_REMED_INFO err=$TOTAL_REMED_ERR" "$LOG"
    echo "Log: $LOG"
}

run_full() {
    require_root
    acquire_remed_lock
    DATE="$(date +%Y%m%d-%H%M%S-%N)"
    create_snapshot
    LOG_PRE="$LOG_AUDIT/audit-pre-${HOSTNAME}-${DATE}.log"
    LOG_R="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
    LOG_POST="$LOG_AUDIT/audit-post-${HOSTNAME}-${DATE}.log"
    need_root_warn
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
    TOTAL_REMED_OK=0; TOTAL_REMED_WARN=0; TOTAL_REMED_SKIP=0; TOTAL_REMED_INFO=0; TOTAL_REMED_ERR=0
    hitss_stamp "REMEDIATION" "START" "$LOG_R"
    run_remed_scripts "$REMED_DIR" "$LOG_R"
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
}

run_menu() {
    local opt
    while true; do
        echo ""
        echo "============================================================"
        echo "HARDENING RHEL8/9 FULL - MENU"
        echo "============================================================"
        echo "1) Audit"
        echo "2) Remediacao"
        echo "3) Full (Audit -> Remed -> Audit)"
        echo "4) Itens em FAIL (ultimo audit)"
        echo "5) Status do ultimo audit"
        echo "6) Rollback (ultimo snapshot)"
        echo "0) Sair"
        echo ""
        read -rp "Escolha: " opt
        case "$opt" in
            1) run_audit ;;
            2) run_remed ;;
            3) run_full ;;
            4) report_unfixed ;;
            5) run_status ;;
            6) run_rollback ;;
            0|q|Q|sair|exit) break ;;
            *) echo "Opcao invalida." ;;
        esac
        echo ""
        read -rp "Pressione ENTER para voltar ao menu..." _
    done
}

case "${1:-menu}" in
    audit)   run_audit ;;
    remed)   run_remed ;;
    full)    run_full ;;
    report)  report_unfixed ;;
    status)  run_status ;;
    rollback) run_rollback "${2:-}" ;;
    menu)    run_menu ;;
    *)
        echo "Uso: $0 {audit|remed|full|report|status|rollback [snapshot]|menu}"
        exit 1
        ;;
esac
