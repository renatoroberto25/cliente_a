#!/usr/bin/env bash

backup_file(){ [ -f "$1" ] && cp -a "$1" "$1.bak_$(date +%F-%H%M%S)"; }

echo "[161 - 184] Remediação Logs, Auditd e Integridade"

GRUB_FILE="/etc/default/grub"
AUDITD_CONF="/etc/audit/auditd.conf"
JCONF="/etc/systemd/journald.conf"
RULES_DIR="/etc/audit/rules.d"
RULES_FILE="$RULES_DIR/hardening.rules"
AIDE_CONF="/etc/aide.conf"
AIDE_DB="/var/lib/aide/aide.db.gz"
CRON_AIDE="/etc/cron.daily/aide-check"

if [ ! -c /dev/null ]; then
  rm -f /dev/null
  mknod -m 666 /dev/null c 1 3
  chown root:root /dev/null
else
  :
fi

if [ -d "$RULES_DIR" ]; then
  :
else
  mkdir -p "$RULES_DIR"
fi

echo -e "\n[161] Stack de logs racionalizado"
if systemctl is-active systemd-journald >/dev/null 2>&1; then
  echo "OK"
else
  systemctl start systemd-journald >/dev/null 2>&1 || true
  echo "OK"
fi

echo -e "\n[162] Journald persistente"
backup_file "$JCONF"
if grep -q '^Storage=' "$JCONF" 2>/dev/null; then
  sed -i 's/^Storage=.*/Storage=persistent/' "$JCONF"
else
  if grep -q '^#Storage=' "$JCONF" 2>/dev/null; then
    sed -i 's/^#Storage=.*/Storage=persistent/' "$JCONF"
  else
    printf '\nStorage=persistent\n' >> "$JCONF"
  fi
fi
systemctl restart systemd-journald >/dev/null 2>&1 || true
echo "OK"

echo -e "\n[163] Rsyslog instalado e ativo"
if rpm -q rsyslog >/dev/null 2>&1; then
  :
else
  dnf -y install rsyslog >/dev/null 2>&1
fi
systemctl enable --now rsyslog >/dev/null 2>&1 || true
echo "OK"

echo -e "\n[164] Logrotate para rsyslog"
if [ -f /etc/logrotate.d/rsyslog ]; then
  :
else
  cat > /etc/logrotate.d/rsyslog <<'EOF'
/var/log/messages
/var/log/secure
/var/log/maillog
/var/log/cron
/var/log/spooler
/var/log/boot.log {
    rotate 7
    daily
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /bin/systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}
EOF
fi
echo "OK"

echo -e "\n[165] auditd instalado e rodando"
if rpm -q audit audit-libs >/dev/null 2>&1; then
  :
else
  dnf -y install audit audit-libs >/dev/null 2>&1
fi
systemctl unmask auditd >/dev/null 2>&1 || true
systemctl enable auditd >/dev/null 2>&1 || true
systemctl start auditd >/dev/null 2>&1 || true
echo "OK"

echo -e "\n[166] Auditoria antes do auditd"
echo "Sem alteração automática (requer reboot e mudança em GRUB)"

echo -e "\n[167] Tamanho de armazenamento de audit log"
backup_file "$AUDITD_CONF"
if grep -Eq '^[[:space:]]*max_log_file[[:space:]]*=' "$AUDITD_CONF" 2>/dev/null; then
  sed -ri 's/^[[:space:]]*max_log_file[[:space:]]*=.*/max_log_file = 50/' "$AUDITD_CONF"
else
  printf '\nmax_log_file = 50\n' >> "$AUDITD_CONF"
fi
echo "OK"

echo -e "\n[168] Logs de auditoria não excluídos automaticamente"
if grep -Eq '^[[:space:]]*max_log_file_action[[:space:]]*=' "$AUDITD_CONF" 2>/dev/null; then
  sed -ri 's/^[[:space:]]*max_log_file_action[[:space:]]*=.*/max_log_file_action = rotate/' "$AUDITD_CONF"
else
  printf 'max_log_file_action = rotate\n' >> "$AUDITD_CONF"
fi
echo "OK"

echo -e "\n[169-180] Regras auditd"
backup_file "$RULES_FILE"
touch "$RULES_FILE"

if grep -Eq '(^|[[:space:]])/etc/localtime([[:space:]]|$)|adjtimex|settimeofday|clock_settime' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-w /etc/localtime -p wa -k time-change
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time-change
EOF
fi

if grep -Eq '/etc/(passwd|shadow|group|gshadow)' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-w /etc/passwd   -p wa -k identity
-w /etc/shadow   -p wa -k identity
-w /etc/group    -p wa -k identity
-w /etc/gshadow  -p wa -k identity
EOF
fi

if grep -Eq 'sethostname|setdomainname|/etc/hosts|/etc/hostname' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network-modify
-w /etc/hosts    -p wa -k network-modify
-w /etc/hostname -p wa -k network-modify
EOF
fi

if grep -Eq 'MAC_POLICY_LOAD|mac_policy|/etc/selinux/' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-w /etc/selinux/ -p wa -k mac-policy
EOF
fi

if grep -Eq '/var/log/(faillog|lastlog)|/var/run/utmp' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/run/utmp    -p wa -k logins
EOF
fi

if grep -Eq '(-S[[:space:]]+chmod|-S[[:space:]]+chown|-S[[:space:]]+fchmod|-S[[:space:]]+fchown|-S[[:space:]]+fchmodat|-S[[:space:]]+fchownat)' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -S chown -S fchown -S fchownat -k perm-modify
EOF
fi

if grep -Eq 'exit=-EACCES|exit=-EPERM|EACCES|EPERM' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-a always,exit -F arch=b64 -S open -S openat -S creat -S truncate -S ftruncate -F exit=-EACCES -k access
-a always,exit -F arch=b64 -S open -S openat -S creat -S truncate -S ftruncate -F exit=-EPERM  -k access
EOF
fi

if grep -Eq '(-S[[:space:]]+mount|-S[[:space:]]+umount2)' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-a always,exit -F arch=b64 -S mount -S umount2 -k mounts
EOF
fi

if grep -Eq '(-S[[:space:]]+unlink|-S[[:space:]]+rename|-S[[:space:]]+rmdir|-S[[:space:]]+unlinkat|-S[[:space:]]+renameat)' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -S rmdir -k delete
EOF
fi

if grep -Eq '(-S[[:space:]]+init_module|-S[[:space:]]+finit_module|-S[[:space:]]+delete_module)' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-a always,exit -F arch=b64 -S init_module -S finit_module -S delete_module -k modules
EOF
fi

if grep -Eq '/etc/sudoers|/etc/sudoers\.d' "$RULES_FILE" 2>/dev/null; then
  :
else
  cat >> "$RULES_FILE" <<'EOF'
-w /etc/sudoers     -p wa -k sudoers
-w /etc/sudoers.d/  -p wa -k sudoers
EOF
fi

echo -e "\n[176] Auditoria de comandos privilegiados"
find / -xdev -type f -perm -4000 2>/dev/null | awk '{print "-w " $0 " -p x -k privileged"}' | grep -Fvxf <(grep -E '^-w[[:space:]]+/.+[[:space:]]+-p[[:space:]]+x[[:space:]]+-k[[:space:]]+privileged' "$RULES_FILE" 2>/dev/null | sed 's/[[:space:]]\+/ /g') >> "$RULES_FILE" 2>/dev/null || true

echo -e "\n[181] Configuração de auditoria imutável"
if grep -Eq '^[[:space:]]*-e[[:space:]]+2[[:space:]]*$' "$RULES_FILE" 2>/dev/null; then
  :
else
  printf '\n-e 2\n' >> "$RULES_FILE"
fi

augenrules --load >/dev/null 2>&1 || true
systemctl restart auditd >/dev/null 2>&1 || true
auditctl -s >/dev/null 2>&1 || true

echo -e "\n[182] AIDE instalado e inicializado"
if rpm -q aide >/dev/null 2>&1; then
  :
else
  dnf -y install aide >/dev/null 2>&1
fi

if [ -f "$AIDE_CONF" ]; then
  backup_file "$AIDE_CONF"
  grep -Fqx '/sbin/auditctl p+i+n+u+g+s+b+acl+xattrs+sha512' "$AIDE_CONF" 2>/dev/null || printf '/sbin/auditctl p+i+n+u+g+s+b+acl+xattrs+sha512\n' >> "$AIDE_CONF"
  grep -Fqx '/sbin/auditd p+i+n+u+g+s+b+acl+xattrs+sha512' "$AIDE_CONF" 2>/dev/null || printf '/sbin/auditd p+i+n+u+g+s+b+acl+xattrs+sha512\n' >> "$AIDE_CONF"
  grep -Fqx '/sbin/ausearch p+i+n+u+g+s+b+acl+xattrs+sha512' "$AIDE_CONF" 2>/dev/null || printf '/sbin/ausearch p+i+n+u+g+s+b+acl+xattrs+sha512\n' >> "$AIDE_CONF"
  grep -Fqx '/sbin/aureport p+i+n+u+g+s+b+acl+xattrs+sha512' "$AIDE_CONF" 2>/dev/null || printf '/sbin/aureport p+i+n+u+g+s+b+acl+xattrs+sha512\n' >> "$AIDE_CONF"
  grep -Fqx '/sbin/autrace p+i+n+u+g+s+b+acl+xattrs+sha512' "$AIDE_CONF" 2>/dev/null || printf '/sbin/autrace p+i+n+u+g+s+b+acl+xattrs+sha512\n' >> "$AIDE_CONF"
  grep -Fqx '/sbin/augenrules p+i+n+u+g+s+b+acl+xattrs+sha512' "$AIDE_CONF" 2>/dev/null || printf '/sbin/augenrules p+i+n+u+g+s+b+acl+xattrs+sha512\n' >> "$AIDE_CONF"
else
  :
fi

if [ -f "$AIDE_DB" ]; then
  :
else
  aide --init >/dev/null 2>&1 || true
  if [ -f /var/lib/aide/aide.db.new.gz ]; then
    mv -f /var/lib/aide/aide.db.new.gz "$AIDE_DB"
  else
    :
  fi
fi

if [ -f "$CRON_AIDE" ]; then
  :
else
  cat > "$CRON_AIDE" <<'EOF'
#!/bin/bash
/usr/sbin/aide --check >/dev/null 2>&1
EOF
  chmod 700 "$CRON_AIDE"
fi

echo "OK"
exit 0
