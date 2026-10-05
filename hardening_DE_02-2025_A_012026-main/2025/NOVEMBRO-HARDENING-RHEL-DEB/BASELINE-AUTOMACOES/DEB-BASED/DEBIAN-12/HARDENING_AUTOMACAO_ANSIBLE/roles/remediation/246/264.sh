#!/usr/bin/env bash
echo "[264–273] Remediação - Regras do auditd"

RULES_DIR="/etc/audit/rules.d"
RULES_FILE="${RULES_DIR}/99-hitss-persistencia.rules"
BACKUP="${RULES_FILE}.bak_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$RULES_DIR"
[ -f "$RULES_FILE" ] && cp "$RULES_FILE" "$BACKUP" && echo "✔ Backup: $BACKUP"

add_rule() {
    local regra="$1"
    auditctl -l | grep -F -- "$regra" >/dev/null && return 0
    grep -R -F -- "$regra" "$RULES_DIR"/*.rules 2>/dev/null | grep -q . && return 0
    echo "$regra" >> "$RULES_FILE" && echo "✔ Regra aplicada: $regra"
}

# 264
add_rule "-w /var/run/utmp -p wa -k session"
add_rule "-w /var/log/wtmp -p wa -k session"
add_rule "-w /var/log/btmp -p wa -k session"

# 265
[ -e /var/log/lastlog ] && add_rule "-w /var/log/lastlog -p wa -k logins"
[ -e /var/run/faillock ] && add_rule "-w /var/run/faillock -p wa -k logins"

# 266
add_rule "-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=unset -k delete"
add_rule "-a always,exit -F arch=b32 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=unset -k delete"

# 267
[ -d /etc/apparmor ] && add_rule "-w /etc/apparmor/ -p wa -k MAC-policy"
[ -d /etc/apparmor.d ] && add_rule "-w /etc/apparmor.d/ -p wa -k MAC-policy"
[ -d /etc/selinux ] && add_rule "-w /etc/selinux/ -p wa -k MAC-policy"

# 268–271
command -v chcon   >/dev/null && add_rule "-a always,exit -F path=/usr/bin/chcon   -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng"
command -v setfacl >/dev/null && add_rule "-a always,exit -F path=/usr/bin/setfacl -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng"
command -v chacl   >/dev/null && add_rule "-a always,exit -F path=/usr/bin/chacl   -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng"
command -v usermod >/dev/null && add_rule "-a always,exit -F path=/usr/sbin/usermod -F perm=x -F auid>=1000 -F auid!=unset -k usermod"

# 272
add_rule "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -F auid>=1000 -F auid!=unset -k modules"
add_rule "-a always,exit -F arch=b32 -S init_module,delete_module -F auid>=1000 -F auid!=unset -k modules"

# 273
grep -q -- "^-e 2" "$RULES_DIR"/*.rules 2>/dev/null || echo "-e 2" >> "$RULES_FILE"

# carregar
augenrules --load && echo "✔ Regras carregadas no kernel"