#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
REPORT_DIR="$LOG_DIR/reports"
HITSS_LOG_FILE="/var/log/hitss-hardening.log"
HITSS_VERSION="HARDENING HITSS v1.3.6 LIGHT"
HITSS_ORIGIN="VIA EXECUCAO LOCAL AUTOMACAO SHELLSCRIPT"
HITSS_FAMILY="RHEL7_8_9"
HOSTNAME="$(hostname -s)"
DATE="$(date +%Y%m%d-%H%M%S-%N)"
RUN_ID=""
RUN_DIR=""
PREFLIGHT_FILE=""
AUDIT_TECH_ERRORS=0
REMED_TECH_ERRORS=0

mkdir -p "$LOG_AUDIT" "$LOG_REMED" "$BACKUP_DIR" "$REPORT_DIR"

MANAGED_FILES=(
    /etc/modprobe.d/99-hitss-hardening.conf
    /etc/modprobe.d/99-hitss-wireless.conf
    /etc/sysctl.d/99-hitss-hardening.conf
    /etc/sysctl.d/99-hitss-network.conf
    /etc/security/limits.d/99-hitss-coredump.conf
    /etc/fstab
    /boot/grub2/grub.cfg
    /boot/grub2/grubenv
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

new_run() {
    DATE="$(date +%Y%m%d-%H%M%S-%N)"
    RUN_ID="hitss-${HOSTNAME}-${DATE}"
    RUN_DIR="$REPORT_DIR/$RUN_ID"
    PREFLIGHT_FILE="$RUN_DIR/precheck.csv"
    install -d -m 0700 "$RUN_DIR"
}

csv_quote() {
    local value="${1//\"/\"\"}"
    printf '"%s"' "$value"
}

record_preflight() {
    local check="$1" severity="$2" result="$3" detail="$4"
    printf '%s,%s,%s,' "$check" "$severity" "$result" >> "$PREFLIGHT_FILE"
    csv_quote "$detail" >> "$PREFLIGHT_FILE"
    printf '\n' >> "$PREFLIGHT_FILE"
    printf '%-22s %-8s %s\n' "$check" "$result" "$detail"
}

is_rhel_like() {
    [ -r /etc/os-release ] || return 1
    (
        . /etc/os-release
        case "${ID:-} ${ID_LIKE:-}" in
            *rhel*|*fedora*|*centos*) exit 0 ;;
            *) exit 1 ;;
        esac
    )
}

run_precheck() {
    local mode="${1:-audit}" hard_fail=0 warn=0 syntax_fail=0 free_kb min_kb major script
    [ -n "$RUN_DIR" ] || new_run
    printf 'CHECK,SEVERITY,RESULT,DETAIL\n' > "$PREFLIGHT_FILE"
    banner "PRE-CHECK OPERACIONAL"

    if is_rhel_like; then
        record_preflight os_family BLOCK PASS "$(os_release)"
    else
        record_preflight os_family BLOCK FAIL "sistema nao identificado como RHEL-like"
        hard_fail=$((hard_fail + 1))
    fi

    major="$(os_major 2>/dev/null || true)"
    if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 7 && major <= 9 )); then
        record_preflight os_version BLOCK PASS "major=$major"
    else
        record_preflight os_version BLOCK FAIL "versao suportada: 7, 8 ou 9; detectada=${major:-unknown}"
        hard_fail=$((hard_fail + 1))
    fi

    if [[ "$mode" == remed || "$mode" == full || "$mode" == rollback ]]; then
        if (( EUID == 0 )); then
            record_preflight root BLOCK PASS "execucao privilegiada"
        else
            record_preflight root BLOCK FAIL "operacao $mode exige root"
            hard_fail=$((hard_fail + 1))
        fi
    elif (( EUID == 0 )); then
        record_preflight root INFO PASS "audit com privilegios completos"
    else
        record_preflight root WARN WARN "audit sem root pode gerar falsos FAIL"
        warn=$((warn + 1))
    fi

    for script in "$BASE_DIR/executor.sh" "$AUDIT_DIR"/*.sh "$REMED_DIR"/*.sh; do
        [ -f "$script" ] || continue
        if ! bash -n "$script"; then
            record_preflight shell_syntax BLOCK FAIL "$script"
            hard_fail=$((hard_fail + 1))
            syntax_fail=$((syntax_fail + 1))
        fi
    done
    (( syntax_fail == 0 )) && record_preflight shell_syntax BLOCK PASS "executor, audit e remediadores validos"

    for script in bash awk sed grep tar find stat; do
        if ! command -v "$script" >/dev/null 2>&1; then
            record_preflight "cmd_$script" BLOCK FAIL "comando obrigatorio ausente"
            hard_fail=$((hard_fail + 1))
        fi
    done

    if command -v systemctl >/dev/null 2>&1; then
        record_preflight systemd BLOCK PASS "systemctl disponivel"
    else
        record_preflight systemd BLOCK FAIL "systemctl ausente"
        hard_fail=$((hard_fail + 1))
    fi

    min_kb="${HITSS_MIN_FREE_KB:-102400}"
    free_kb="$(df -Pk "$LOG_DIR" | awk 'NR==2 {print $4}')"
    if [[ "$free_kb" =~ ^[0-9]+$ ]] && (( free_kb >= min_kb )); then
        record_preflight disk_free BLOCK PASS "${free_kb} KB livres"
    else
        record_preflight disk_free BLOCK FAIL "livre=${free_kb:-unknown} KB minimo=$min_kb KB"
        hard_fail=$((hard_fail + 1))
    fi

    if command -v sshd >/dev/null 2>&1 && [ -f /etc/ssh/sshd_config ]; then
        if sshd -t -f /etc/ssh/sshd_config >/dev/null 2>&1; then
            record_preflight sshd_config BLOCK PASS "configuracao atual valida"
        else
            record_preflight sshd_config BLOCK FAIL "sshd -t rejeitou a configuracao atual"
            hard_fail=$((hard_fail + 1))
        fi
    else
        record_preflight sshd_config INFO SKIP "sshd nao instalado"
    fi

    if command -v visudo >/dev/null 2>&1; then
        if visudo -cf /etc/sudoers >/dev/null 2>&1; then
            record_preflight sudoers BLOCK PASS "configuracao atual valida"
        else
            record_preflight sudoers BLOCK FAIL "visudo rejeitou a configuracao atual"
            hard_fail=$((hard_fail + 1))
        fi
    else
        record_preflight sudoers WARN SKIP "visudo nao encontrado"
        warn=$((warn + 1))
    fi

    if command -v authselect >/dev/null 2>&1 && ! authselect check >/dev/null 2>&1; then
        record_preflight authselect WARN WARN "perfil customizado ou inconsistente; PAM exige revisao"
        warn=$((warn + 1))
    else
        record_preflight authselect INFO PASS "nao bloqueante"
    fi

    if (( hard_fail > 0 )); then
        echo "PRE-CHECK: FAIL ($hard_fail bloqueio(s), $warn aviso(s))"
        return 2
    fi
    echo "PRE-CHECK: PASS ($warn aviso(s))"
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
    local archive="${snapshot}.tar.gz" file repo entry

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
    for entry in /boot/loader/entries/*.conf; do
        [ -e "$entry" ] && printf '%s\n' "${entry#/}" >> "$present"
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

write_hash_manifest() {
    local output="$RUN_DIR/artifacts.sha256" file
    : > "$output"
    if ! command -v sha256sum >/dev/null 2>&1; then
        printf 'sha256sum indisponivel\n' > "$output"
        return
    fi
    for file in "$BASE_DIR/executor.sh" "$AUDIT_DIR"/*.sh "$REMED_DIR"/*.sh; do
        [ -f "$file" ] && sha256sum "$file" >> "$output"
    done
    for file in "$BASE_DIR"/baseline_rhel_light_resumido.csv; do
        [ -f "$file" ] && sha256sum "$file" >> "$output"
    done
}

generate_control_comparison() {
    local pre="$1" post="$2" output="$RUN_DIR/controls.csv"
    awk -F, '
        function quote(s) { gsub(/"/, "\"\"", s); return "\"" s "\"" }
        FNR==NR {
            if ($1 ~ /^[0-9]+$/ && $4 ~ /^(PASS|FAIL)$/) {
                pre[$1]=$4; name[$1]=$2; severity[$1]=$3
            }
            next
        }
        $1 ~ /^[0-9]+$/ && $4 ~ /^(PASS|FAIL)$/ {
            post[$1]=$4
            if (!($1 in name)) { name[$1]=$2; severity[$1]=$3 }
        }
        END {
            print "ID,NOME,CRITICIDADE,ANTES,DEPOIS,TRANSICAO"
            for (id in name) {
                before=(id in pre ? pre[id] : "MISSING")
                after=(id in post ? post[id] : "MISSING")
                if (before=="FAIL" && after=="PASS") transition="FIXED"
                else if (before=="PASS" && after=="FAIL") transition="REGRESSION"
                else if (before==after) transition="UNCHANGED"
                else transition="ERROR"
                rows[id]=id "," quote(name[id]) "," quote(severity[id]) "," before "," after "," transition
            }
            for (i=0; i<=9999; i++) if (i in rows) print rows[i]
        }
    ' "$pre" "$post" > "$output"
}

generate_full_report() {
    local pre="$1" remed="$2" post="$3"
    local fixed regressions unchanged missing status summary_csv summary_json summary_txt end_utc
    generate_control_comparison "$pre" "$post"
    fixed="$(awk -F, '$6=="FIXED" {n++} END {print n+0}' "$RUN_DIR/controls.csv")"
    regressions="$(awk -F, '$6=="REGRESSION" {n++} END {print n+0}' "$RUN_DIR/controls.csv")"
    unchanged="$(awk -F, '$6=="UNCHANGED" {n++} END {print n+0}' "$RUN_DIR/controls.csv")"
    missing="$(awk -F, '$6=="ERROR" {n++} END {print n+0}' "$RUN_DIR/controls.csv")"
    status=SUCCESS
    (( post_fail > 0 || TOTAL_REMED_WARN > 0 || TOTAL_REMED_SKIP > 0 )) && status=PARTIAL
    (( regressions > 0 || AUDIT_TECH_ERRORS > 0 || REMED_TECH_ERRORS > 0 || missing > 0 )) && status=FAILED
    end_utc="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

    summary_csv="$RUN_DIR/summary.csv"
    printf 'RUN_ID,HOST,VERSION,STATUS,PRE_PASS,PRE_FAIL,POST_PASS,POST_FAIL,FIXED,REGRESSIONS,UNCHANGED,MISSING,REMED_OK,REMED_WARN,REMED_SKIP,REMED_INFO,REMED_ERROR,AUDIT_ERROR,SNAPSHOT\n' > "$summary_csv"
    printf '%s,%s,"%s",%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,"%s"\n' \
        "$RUN_ID" "$HOSTNAME" "$HITSS_VERSION" "$status" "$pre_pass" "$pre_fail" "$post_pass" "$post_fail" \
        "$fixed" "$regressions" "$unchanged" "$missing" "$TOTAL_REMED_OK" "$TOTAL_REMED_WARN" \
        "$TOTAL_REMED_SKIP" "$TOTAL_REMED_INFO" "$REMED_TECH_ERRORS" "$AUDIT_TECH_ERRORS" "${LAST_SNAPSHOT:-}" >> "$summary_csv"

    summary_json="$RUN_DIR/summary.json"
    cat > "$summary_json" <<EOF
{
  "run_id": "$RUN_ID",
  "host": "$HOSTNAME",
  "version": "$HITSS_VERSION",
  "status": "$status",
  "finished_utc": "$end_utc",
  "audit": {"pre_pass": $pre_pass, "pre_fail": $pre_fail, "post_pass": $post_pass, "post_fail": $post_fail, "technical_errors": $AUDIT_TECH_ERRORS},
  "comparison": {"fixed": $fixed, "regressions": $regressions, "unchanged": $unchanged, "missing": $missing},
  "remediation": {"ok": $TOTAL_REMED_OK, "warn": $TOTAL_REMED_WARN, "skip": $TOTAL_REMED_SKIP, "info": $TOTAL_REMED_INFO, "technical_errors": $REMED_TECH_ERRORS},
  "snapshot": "${LAST_SNAPSHOT:-}",
  "artifacts": {"precheck": "$PREFLIGHT_FILE", "audit_pre": "$pre", "remediation": "$remed", "audit_post": "$post", "controls": "$RUN_DIR/controls.csv"}
}
EOF

    summary_txt="$RUN_DIR/summary.txt"
    {
        printf 'RUN_ID: %s\nSTATUS: %s\nHOST: %s\nVERSION: %s\n' "$RUN_ID" "$status" "$HOSTNAME" "$HITSS_VERSION"
        printf 'ANTES: PASS=%s FAIL=%s\nDEPOIS: PASS=%s FAIL=%s\n' "$pre_pass" "$pre_fail" "$post_pass" "$post_fail"
        printf 'CORRIGIDOS=%s REGRESSOES=%s INALTERADOS=%s AUSENTES=%s\n' "$fixed" "$regressions" "$unchanged" "$missing"
        printf 'REMED: OK=%s WARN=%s SKIP=%s INFO=%s ERROR=%s\n' "$TOTAL_REMED_OK" "$TOTAL_REMED_WARN" "$TOTAL_REMED_SKIP" "$TOTAL_REMED_INFO" "$REMED_TECH_ERRORS"
        printf 'SNAPSHOT: %s\n' "${LAST_SNAPSHOT:-}"
    } > "$summary_txt"
    write_hash_manifest
    printf '%s\n' "$status"
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
    acquire_remed_lock
    create_snapshot
    TOTAL_REMED_OK=0; TOTAL_REMED_WARN=0; TOTAL_REMED_SKIP=0; TOTAL_REMED_INFO=0; TOTAL_REMED_ERR=0
    REMED_TECH_ERRORS=0
    LOG="$LOG_REMED/remed-${HOSTNAME}-${DATE}.log"
    need_root_warn
    hitss_stamp "REMEDIATION" "START" "$LOG"
    banner "REMEDIACAO"
    run_remed_scripts "$REMED_DIR" "$LOG"
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
    acquire_remed_lock
    create_snapshot
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
    final_status="$(generate_full_report "$LOG_PRE" "$LOG_R" "$LOG_POST")"
    echo "REPORT: $RUN_DIR"
    echo "STATUS: $final_status"
    hitss_stamp "FULL" "REPORT status=$final_status run_id=$RUN_ID" "$RUN_DIR/summary.json"

    if [[ "$final_status" == FAILED ]]; then
        return 4
    fi
    if [[ "$final_status" == PARTIAL && "${HITSS_FAIL_ON_NONCOMPLIANCE:-0}" == 1 ]]; then
        return 3
    fi
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
        echo "HARDENING RHEL 7/8/9 - MENU"
        echo "============================================================"
        echo "1) Audit"
        echo "2) Pre-check operacional"
        echo "3) Remediacao"
        echo "4) Full (Pre-check -> Audit -> Remed -> Audit -> Report)"
        echo "5) Itens em FAIL (ultimo audit)"
        echo "6) Status do ultimo audit"
        echo "7) Rollback (ultimo snapshot)"
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
            7) run_rollback || echo "Rollback concluido com status $?." ;;
            0|q|Q|sair|exit) break ;;
            *) echo "Opcao invalida." ;;
        esac
        echo ""
        read -rp "Pressione ENTER para voltar ao menu..." _
    done
}

main() {
    case "${1:-menu}" in
        audit)    run_audit ;;
        precheck) run_precheck_only "${2:-full}" ;;
        remed)    run_remed ;;
        full)     run_full ;;
        report)   report_unfixed ;;
        status)   run_status ;;
        rollback) run_rollback "${2:-}" ;;
        menu)     run_menu ;;
        *)
            echo "Uso: $0 {precheck [audit|remed|full]|audit|remed|full|report|status|rollback [snapshot]|menu}"
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
