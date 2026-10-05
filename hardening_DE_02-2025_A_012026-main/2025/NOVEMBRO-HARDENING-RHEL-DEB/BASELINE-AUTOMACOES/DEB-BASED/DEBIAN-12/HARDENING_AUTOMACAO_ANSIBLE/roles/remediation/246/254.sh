#!/usr/bin/env bash
# [254–263] Remediação - Regras de auditoria do auditd

RULES_FILE="/etc/audit/rules.d/50-hardening.rules"
BACKUP_FILE="${RULES_FILE}.bak_$(date +%Y%m%d_%H%M%S)"

# Garante que arquivo existe
if [ ! -f "$RULES_FILE" ]; then
    touch "$RULES_FILE"
fi

# Cria backup
cp "$RULES_FILE" "$BACKUP_FILE"

add_rule() {
    local rule="$1"
    grep -qF -- "$rule" "$RULES_FILE" || echo "$rule" >> "$RULES_FILE"
}

echo "[254] Garantindo regras persistentes em $RULES_FILE"

# [255] passwd
add_rule "-w /etc/passwd -p wa -k identity"

# [256] shadow
add_rule "-w /etc/shadow -p wa -k identity"

# [257] alterações de hora
add_rule "-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change"
add_rule "-a always,exit -F arch=b32 -S adjtimex,settimeofday,clock_settime -k time-change"
add_rule "-w /etc/localtime -p wa -k time-change"

# [258] módulos de kernel
add_rule "-w /sbin/insmod -p x -k modules"
add_rule "-w /sbin/rmmod -p x -k modules"
add_rule "-w /sbin/modprobe -p x -k modules"

# [259] sudo
add_rule "-w /etc/sudoers -p wa -k scope"
add_rule "-w /etc/sudoers.d -p wa -k scope"

# [260] su
add_rule "-w /bin/su -p x -k su"

# [261] rede / hostname
add_rule "-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale"
add_rule "-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale"
add_rule "-w /etc/issue -p wa -k system-locale"
add_rule "-w /etc/issue.net -p wa -k system-locale"
add_rule "-w /etc/hosts -p wa -k system-locale"
add_rule "-w /etc/network/ -p wa -k system-locale"
add_rule "-w /etc/netplan/ -p wa -k system-locale"

# [262] acessos negados
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
if [ -n "$UID_MIN" ]; then
    add_rule "-a always,exit -F arch=b64 -S open,openat,creat,truncate,ftruncate -F exit=-EACCES -F auid>=$UID_MIN -F auid!=unset -k access"
    add_rule "-a always,exit -F arch=b64 -S open,openat,creat,truncate,ftruncate -F exit=-EPERM  -F auid>=$UID_MIN -F auid!=unset -k access"
    add_rule "-a always,exit -F arch=b32 -S open,openat,creat,truncate,ftruncate -F exit=-EACCES -F auid>=$UID_MIN -F auid!=unset -k access"
    add_rule "-a always,exit -F arch=b32 -S open,openat,creat,truncate,ftruncate -F exit=-EPERM  -F auid>=$UID_MIN -F auid!=unset -k access"
fi

# [263] identidade de usuários/grupos
add_rule "-w /etc/group -p wa -k identity"
add_rule "-w /etc/gshadow -p wa -k identity"
add_rule "-w /etc/security/opasswd -p wa -k identity"
add_rule "-w /etc/nsswitch.conf -p wa -k identity"
add_rule "-w /etc/pam.d/ -p wa -k identity"

echo "[*] Recarregando regras com augenrules..."
augenrules --load

# Testa se regras foram aplicadas
if auditctl -l | grep -q "identity"; then
    echo "✅ Regras aplicadas com sucesso"
else
    echo "⚠️ Verifique manualmente: algumas regras podem não ter sido carregadas"
fi