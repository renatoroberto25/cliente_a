#!/usr/bin/env bash
set -euo pipefail

backup() {
    [ -f "$1" ] && cp -a "$1" "$1.bak_$(date +%F-%H%M%S)"
}

###############################################################################
# 161 – Stack de logs racionalizado
###############################################################################
echo "[161] Stack de logs racionalizado"
systemctl is-active systemd-journald &>/dev/null || systemctl start systemd-journald

###############################################################################
# 162 – Journald configurado
###############################################################################
echo "[162] Configurar journald"
JCONF="/etc/systemd/journald.conf"
backup "$JCONF"
grep -q '^SystemMaxUse=' "$JCONF" || echo "SystemMaxUse=200M" >> "$JCONF"
grep -q '^SystemKeepFree=' "$JCONF" || echo "SystemKeepFree=50M" >> "$JCONF"
systemctl restart systemd-journald

###############################################################################
# 163 – Rsyslog instalado e ativo
###############################################################################
echo "[163] Rsyslog instalado e ativo"
rpm -q rsyslog &>/dev/null || yum install -y rsyslog
systemctl enable --now rsyslog

###############################################################################
# 164 – Logrotate para rsyslog
###############################################################################
echo "[164] Logrotate configurado"
grep -qi rsyslog /etc/logrotate.d/* 2>/dev/null || cat <<EOF >/etc/logrotate.d/rsyslog
/var/log/messages /var/log/secure /var/log/cron {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF

###############################################################################
# 165 – auditd instalado e ativo
###############################################################################
echo "[165] auditd instalado e ativo"
rpm -q audit audit-libs &>/dev/null || yum install -y audit audit-libs
systemctl unmask auditd || true
systemctl enable --now auditd || true

###############################################################################
# 166 – Auditoria antes do auditd (audit=1)
###############################################################################
echo "[166] audit=1 no kernel"
GRUB="/etc/default/grub"
backup "$GRUB"
grep -q 'audit=1' "$GRUB" || {
    sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="audit=1 /' "$GRUB"
    grub2-mkconfig -o /boot/grub2/grub.cfg
}

###############################################################################
# 167 – Tamanho do audit log
###############################################################################
echo "[167] max_log_file"
AUDITD="/etc/audit/auditd.conf"
backup "$AUDITD"
sed -i 's/^max_log_file.*/max_log_file = 50/' "$AUDITD"
grep -q '^max_log_file' "$AUDITD" || echo "max_log_file = 50" >> "$AUDITD"

###############################################################################
# 168 – Logs não excluídos automaticamente
###############################################################################
echo "[168] max_log_file_action"
sed -i 's/^max_log_file_action.*/max_log_file_action = rotate/' "$AUDITD"
grep -q '^max_log_file_action' "$AUDITD" || echo "max_log_file_action = rotate" >> "$AUDITD"

###############################################################################
# Preparação de regras
###############################################################################
RULES="/etc/audit/rules.d/hardening.rules"
backup "$RULES"
: > "$RULES"

###############################################################################
# 169 – Data/Hora
###############################################################################
echo "[169] Auditoria data/hora"
cat <<EOF >>"$RULES"
-w /etc/localtime -p wa -k time-change
-a always,exit -S adjtimex -S settimeofday -k time-change
EOF

###############################################################################
# 170 – Contas/Grupos
###############################################################################
echo "[170] Auditoria contas"
cat <<EOF >>"$RULES"
-w /etc/passwd  -p wa -k identity
-w /etc/shadow  -p wa -k identity
-w /etc/group   -p wa -k identity
-w /etc/gshadow -p wa -k identity
EOF

###############################################################################
# 171 – Rede
###############################################################################
echo "[171] Auditoria rede"
cat <<EOF >>"$RULES"
-a always,exit -S sethostname -S setdomainname -k network
-w /etc/hosts -p wa -k network
-w /etc/hostname -p wa -k network
EOF

###############################################################################
# 172 – MAC (SELinux)
###############################################################################
echo "[172] Auditoria MAC"
echo "-w /usr/share/selinux/ -p wa -k MAC_POLICY_LOAD" >> "$RULES"

###############################################################################
# 173 – Login/logout
###############################################################################
echo "[173] Auditoria login/logout"
cat <<EOF >>"$RULES"
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/run/utmp -p wa -k logins
EOF

###############################################################################
# 174 – DAC
###############################################################################
echo "[174] Auditoria DAC"
echo "-a always,exit -S chmod -S fchmod -S fchmodat -k perm-modify" >> "$RULES"

###############################################################################
# 175 – Acessos não autorizados
###############################################################################
echo "[175] Auditoria EACCES/EPERM"
echo "-a always,exit -S open -S openat -F exit=-EACCES -k unauthorized" >> "$RULES"
echo "-a always,exit -S open -S openat -F exit=-EPERM  -k unauthorized" >> "$RULES"

###############################################################################
# 176 – SUID
###############################################################################
echo "[176] Auditoria SUID"
find / -xdev -perm -4000 2>/dev/null | while read f; do
    echo "-w $f -p x -k privileged" >> "$RULES"
done

###############################################################################
# 177 – Mount
###############################################################################
echo "[177] Auditoria mount"
echo "-a always,exit -S mount -S umount2 -k mounts" >> "$RULES"

###############################################################################
# 178 – Deleção
###############################################################################
echo "[178] Auditoria deleção"
echo "-a always,exit -S unlink -S unlinkat -S rename -S renameat -k delete" >> "$RULES"

###############################################################################
# 179 – Kernel modules
###############################################################################
echo "[179] Auditoria kernel modules"
echo "-a always,exit -S init_module -S finit_module -S delete_module -k modules" >> "$RULES"

###############################################################################
# 180 – sudoers
###############################################################################
echo "[180] Auditoria sudoers"
echo "-w /etc/sudoers -p wa -k sudoers" >> "$RULES"
echo "-w /etc/sudoers.d/ -p wa -k sudoers" >> "$RULES"

###############################################################################
# 181 – Imutável (seguro)
###############################################################################
echo "[181] Auditoria imutável"
augenrules --load
auditctl -e 2 || true
systemctl restart auditd
