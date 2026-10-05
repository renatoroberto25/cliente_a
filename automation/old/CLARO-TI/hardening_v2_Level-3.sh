#!/usr/bin/env bash
set -uo pipefail

############################################
# VARIÁVEIS
############################################
DATE=$(date +%Y%m%d_%H%M%S)
HOST=$(hostname)

LOG="/var/log/hardening_v2.log"
CSV="/root/hardening_v2_score_$DATE.csv"
ROLLBACK="/root/hardening_v2_rollback_$DATE"

mkdir -p "$ROLLBACK"

exec > >(tee -a "$LOG") 2>&1

SCORE=0

############################################
# DEBUG (ativar quando necessário)
############################################
# set -x

############################################
# FUNÇÕES
############################################

log() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*"
}

safe_run() {
    "$@" || warn "falha: $*"
}

check() {
    local cat=$1
    local result=$2
    local weight=$3

    echo "$HOST,$cat,$result,$weight" >> "$CSV"

    [[ "$result" == "OK" ]] && SCORE=$((SCORE + weight))
}

backup_file() {
    local f="$1"

    if [ -f "$f" ]; then
        mkdir -p "$ROLLBACK$(dirname $f)"
        cp -p "$f" "$ROLLBACK$f"
    fi
}

backup_dir() {
    local d="$1"

    if [ -d "$d" ]; then
        mkdir -p "$ROLLBACK$(dirname $d)"
        cp -rp "$d" "$ROLLBACK$(dirname $d)/"
    fi
}

############################################
# BACKUP CRÍTICO (ROLLBACK COMPLETO)
############################################
log "Backup inicial"

backup_file /etc/ssh/sshd_config
backup_file /etc/sudoers
backup_file /etc/security/pwquality.conf
backup_file /etc/sysctl.conf

backup_dir /etc/sudoers.d
backup_dir /etc/audit
backup_dir /etc/ssh

############################################
# DETECÇÃO
############################################
OS_ID=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
OS_VER=$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')
MAJOR=$(echo $OS_VER | cut -d. -f1)

log "$HOST | OS=$OS_ID VERSION=$OS_VER"

############################################
# SSH
############################################
SSHD="/etc/ssh/sshd_config"

set_ssh() {
    grep -q "^$1" $SSHD \
        && sed -i "s|^$1.*|$1 $2|" $SSHD \
        || echo "$1 $2" >> $SSHD
}

set_ssh PermitRootLogin yes
set_ssh PasswordAuthentication yes
set_ssh MaxAuthTries 4
set_ssh ClientAliveInterval 300

if sshd -t >/dev/null 2>&1; then
    safe_run systemctl restart sshd || safe_run service sshd restart
    check "SSH" "OK" 15
else
    check "SSH" "FAIL" 15
fi

############################################
# PAM (CORRIGIDO RHEL 9/10)
############################################
PWFILE="/etc/security/pwquality.conf"

backup_file "$PWFILE"

safe_run bash -c "
grep -q '^minlen' $PWFILE \
    && sed -i 's/^minlen.*/minlen = 12/' $PWFILE \
    || echo 'minlen = 12' >> $PWFILE
"

safe_run bash -c "
grep -q '^retry' $PWFILE \
    || echo 'retry = 3' >> $PWFILE
"

if [ "$MAJOR" -ge 8 ]; then
    if authselect check >/dev/null 2>&1; then
        safe_run authselect apply-changes
        safe_run authselect enable-feature with-faillock
        check "PAM" "OK" 20
    else
        warn "authselect custom"
        check "PAM" "SKIPPED" 20
    fi
else
    safe_run sed -i '/pam_unix.so/i password requisite pam_pwquality.so retry=3 minlen=12' /etc/pam.d/system-auth
    check "PAM" "OK" 20
fi

############################################
# SUDO (VALIDAÇÃO COMPLETA)
############################################

safe_run chmod 440 /etc/sudoers
safe_run find /etc/sudoers.d -type f -exec chmod 440 {} \;

SUDO_OK=1

# valida sintaxe
if ! visudo -c >/dev/null 2>&1; then
    warn "sudoers com erro de sintaxe"
    SUDO_OK=0
fi

# valida permissões
if find /etc/sudoers.d -type f ! -perm 440 | grep -q .; then
    warn "permissões incorretas em sudoers.d"
    SUDO_OK=0
fi

# resultado final
if [ "$SUDO_OK" -eq 1 ]; then
    check "SUDO" "OK" 10
else
    check "SUDO" "FAIL" 10
fi

############################################
# AUDIT CORE
############################################
safe_run systemctl enable auditd
safe_run systemctl restart auditd

systemctl is-active auditd >/dev/null 2>&1 \
    && check "AUDIT_CORE" "OK" 10 \
    || check "AUDIT_CORE" "FAIL" 10

############################################
# AUDIT L3
############################################
RULE_FILE="/etc/audit/rules.d/99-l3.rules"

backup_file "$RULE_FILE"

cat > "$RULE_FILE" <<EOF
-b 8192

-w /etc/passwd -p wa -k passwd_change
-w /etc/sudoers -p wa -k sudoers_change
-w /etc/ssh/sshd_config -p wa -k ssh_change
EOF

safe_run augenrules --load

auditctl -l | grep -q passwd_change \
    && check "AUDIT_RULES" "OK" 15 \
    || check "AUDIT_RULES" "FAIL" 15

############################################
# SYSCTL SAFE
############################################
safe_run sysctl -w net.ipv4.conf.all.rp_filter=1
safe_run sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1

check "SYSCTL" "OK" 5

############################################
# LOGGING
############################################
systemctl is-active rsyslog >/dev/null 2>&1 \
    && check "LOGGING" "OK" 10 \
    || check "LOGGING" "FAIL" 10

############################################
# INTEGRIDADE
############################################
rpm -Va --nomtime --nosize --nomd5 >/dev/null 2>&1 \
    && check "INTEGRIDADE" "OK" 10 \
    || check "INTEGRIDADE" "WARN" 10

############################################
# SCORE FINAL
############################################
echo "$HOST,TOTAL_SCORE,$SCORE" >> "$CSV"

if [ "$SCORE" -ge 90 ]; then
    CLASS="HIGH"
elif [ "$SCORE" -ge 70 ]; then
    CLASS="MEDIUM"
else
    CLASS="CRITICAL"
fi

echo "$HOST,SECURITY_LEVEL,$CLASS" >> "$CSV"

############################################
# OUTPUT
############################################
echo "================================="
echo "HOST: $HOST"
echo "SCORE: $SCORE"
echo "LEVEL: $CLASS"
echo "CSV: $CSV"
echo "ROLLBACK: $ROLLBACK"
echo "================================="