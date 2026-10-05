#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: logs, auditd e integridade"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"
JOURNALD_CONF="/etc/systemd/journald.conf"
AUDITD_CONF="/etc/audit/auditd.conf"
RULES_DIR="/etc/audit/rules.d"
RULES_FILE="$RULES_DIR/99-hitss-hardening.rules"

backup_file() {
    local file="$1"
    [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null || true
}

ensure_file() {
    local file="$1" dir
    dir="$(dirname "$file")"
    if [ ! -d "$dir" ]; then
        echo "WARN: diretorio ausente: $dir"
        return 1
    fi
    [ -e "$file" ] || touch "$file"
}

ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" 2>/dev/null || {
            echo "WARN: diretorio ausente e nao criado: $dir"
            return 1
        }
    fi
}

set_key_value() {
    local file="$1" key="$2" value="$3" pattern
    pattern="${key//./\\.}"
    ensure_file "$file" || return
    backup_file "$file"

    if grep -Eq "^[[:space:]]*#?[[:space:]]*${pattern}[[:space:]]*=" "$file"; then
        sed -i "s|^[[:space:]]*#\\?[[:space:]]*${pattern}[[:space:]]*=.*|${key}=${value}|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
    echo "OK: ${key}=${value} em $file"
}

set_auditd_value() {
    local key="$1" value="$2" pattern
    pattern="${key//./\\.}"
    ensure_file "$AUDITD_CONF" || return

    backup_file "$AUDITD_CONF"
    if grep -Eq "^[[:space:]]*${pattern}[[:space:]]*=" "$AUDITD_CONF"; then
        sed -i "s|^[[:space:]]*${pattern}[[:space:]]*=.*|${key} = ${value}|" "$AUDITD_CONF"
    else
        printf '%s = %s\n' "$key" "$value" >> "$AUDITD_CONF"
    fi
    echo "OK: ${key} = ${value} em $AUDITD_CONF"
}

add_rule() {
    local desc="$1" line="$2"
    if grep -Fxq "$line" "$RULES_FILE" 2>/dev/null; then
        echo "OK: regra ja presente - $desc"
    else
        printf '%s\n' "$line" >> "$RULES_FILE"
        echo "OK: regra adicionada - $desc"
    fi
}

load_audit_rules() {
    if ! command -v auditctl >/dev/null 2>&1; then
        echo "SKIP: auditctl ausente; regras persistidas, mas nao carregadas em runtime"
        return
    fi

    if auditctl -s 2>/dev/null | grep -Eq '^[[:space:]]*enabled[[:space:]]+2\b'; then
        echo "WARN: auditd ja esta imutavel; novas regras persistidas so entram apos reboot"
        return
    fi

    if command -v augenrules >/dev/null 2>&1; then
        if augenrules --load >/dev/null 2>&1; then
            echo "OK: regras auditd carregadas com augenrules --load"
            return
        fi
        echo "WARN: augenrules --load falhou; tentando auditctl -R"
    fi

    if auditctl -R "$RULES_FILE" >/dev/null 2>&1; then
        echo "OK: regras auditd carregadas com auditctl -R"
    else
        echo "WARN: regras persistidas, mas auditctl nao aceitou carga runtime"
    fi
}

echo "[162] Journald persistente"
set_key_value "$JOURNALD_CONF" Storage persistent
echo "INFO: systemd-journald nao foi reiniciado automaticamente"

echo "[164] Logrotate para rsyslog"
if [ -f /etc/logrotate.conf ]; then
    backup_file /etc/logrotate.conf
    if grep -Eq '^[[:space:]]*rotate[[:space:]]+[1-9][0-9]*' /etc/logrotate.conf; then
        echo "OK: rotate ja configurado em /etc/logrotate.conf"
    else
        printf '%s\n' 'rotate 4' >> /etc/logrotate.conf
        echo "OK: rotate 4 adicionado em /etc/logrotate.conf"
    fi
fi
if [ -d /etc/logrotate.d ]; then
    if [ -f /etc/logrotate.d/rsyslog ]; then
        echo "OK: /etc/logrotate.d/rsyslog existente"
    else
        cat > /etc/logrotate.d/rsyslog <<'RSYSLOG_ROTATE'
/var/log/messages
/var/log/secure
/var/log/maillog
/var/log/cron
/var/log/spooler
/var/log/boot.log
{
    rotate 4
    weekly
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        /usr/bin/systemctl reload rsyslog.service >/dev/null 2>&1 || true
    endscript
}
RSYSLOG_ROTATE
        chmod 0644 /etc/logrotate.d/rsyslog 2>/dev/null || true
        echo "OK: /etc/logrotate.d/rsyslog criado"
    fi
else
    echo "SKIP: /etc/logrotate.d ausente"
fi

echo "[166] Auditoria antes do auditd"
echo "SKIP: parametro audit=1 exige GRUB/reboot e janela controlada"

echo "[167] Retencao de logs auditd"
set_auditd_value max_log_file 50

echo "[169-175,177-180] Regras persistentes auditd"
if ensure_file "$RULES_FILE"; then
    backup_file "$RULES_FILE"
    add_rule "time-change localtime" "-w /etc/localtime -p wa -k time-change"
    add_rule "time-change syscalls" "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time-change"
    add_rule "identity passwd" "-w /etc/passwd -p wa -k identity"
    add_rule "identity shadow" "-w /etc/shadow -p wa -k identity"
    add_rule "identity group" "-w /etc/group -p wa -k identity"
    add_rule "identity gshadow" "-w /etc/gshadow -p wa -k identity"
    add_rule "network hostname syscalls" "-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network-modify"
    add_rule "network hosts" "-w /etc/hosts -p wa -k network-modify"
    add_rule "network hostname" "-w /etc/hostname -p wa -k network-modify"
    add_rule "network resolv" "-w /etc/resolv.conf -p wa -k network-modify"
    add_rule "logins faillog" "-w /var/log/faillog -p wa -k logins"
    add_rule "logins lastlog" "-w /var/log/lastlog -p wa -k logins"
    add_rule "logins utmp" "-w /var/run/utmp -p wa -k logins"
    add_rule "permissoes DAC" "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -S chown -S fchown -S fchownat -k perm-modify"
    add_rule "acesso negado EACCES" "-a always,exit -F arch=b64 -S open -S openat -S creat -S truncate -S ftruncate -F exit=-EACCES -k access"
    add_rule "acesso negado EPERM" "-a always,exit -F arch=b64 -S open -S openat -S creat -S truncate -S ftruncate -F exit=-EPERM -k access"
    add_rule "mounts" "-a always,exit -F arch=b64 -S mount -S umount2 -k mounts"
    add_rule "delete" "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -S rmdir -k delete"
    add_rule "kernel modules" "-a always,exit -F arch=b64 -S init_module -S finit_module -S delete_module -k modules"
    add_rule "sudoers file" "-w /etc/sudoers -p wa -k sudoers"
    add_rule "sudoers dir" "-w /etc/sudoers.d/ -p wa -k sudoers"
    load_audit_rules
fi

echo "OK"
exit 0
