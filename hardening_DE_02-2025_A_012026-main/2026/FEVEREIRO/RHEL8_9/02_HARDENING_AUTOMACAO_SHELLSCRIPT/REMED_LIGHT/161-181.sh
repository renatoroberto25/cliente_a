#!/usr/bin/env bash

backup_file() {
    [ -f "$1" ] && cp "$1" "$1.bak_$(date +%F-%H%M%S)"
}

###############################################################################
# FIX ESTRUTURAL 0 – Garantir /dev/null íntegro (evita avalanche de logs)
###############################################################################
if [ ! -c /dev/null ]; then
    rm -f /dev/null
    mknod -m 666 /dev/null c 1 3
    chown root:root /dev/null
fi

###############################################################################
# FIX ESTRUTURAL 1 – Ajustar backlog para evitar “kauditd hold queue overflow”
###############################################################################
GRUB_FILE="/etc/default/grub"
backup_file "$GRUB_FILE"

if ! grep -q 'audit_backlog_limit=' "$GRUB_FILE"; then
    sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="audit_backlog_limit=8192 /' "$GRUB_FILE"
fi

grub2-mkconfig -o /boot/grub2/grub.cfg &>/dev/null

# Ajustar auditd.conf também
AUDITD="/etc/audit/auditd.conf"
backup_file "$AUDITD"
grep -q '^backlog_limit' "$AUDITD" || echo "backlog_limit = 8192" >> "$AUDITD"

###############################################################################
# 161 – Stack de logs racionalizado
###############################################################################
echo -e "\n[161] Racionalizar stack de logs"
systemctl is-active systemd-journald &>/dev/null || systemctl start systemd-journald

###############################################################################
# 162 – Journald configurado
###############################################################################
echo -e "\n[162] Configurar journald"
JCONF="/etc/systemd/journald.conf"
backup_file "$JCONF"

grep -Eq '^SystemMaxUse=' "$JCONF" || echo "SystemMaxUse=200M" >> "$JCONF"
grep -Eq '^SystemKeepFree=' "$JCONF" || echo "SystemKeepFree=50M" >> "$JCONF"

systemctl restart systemd-journald

###############################################################################
# 163 – Rsyslog instalado e ativo
###############################################################################
echo -e "\n[163] Instalar e ativar rsyslog"
if ! rpm -q rsyslog &>/dev/null; then
    dnf install -y rsyslog
fi
systemctl enable --now rsyslog

###############################################################################
# 164 – Logrotate para rsyslog
###############################################################################
echo -e "\n[164] Configurar logrotate para rsyslog"
if ! grep -qi 'rsyslog' /etc/logrotate.d/*; then
    cat <<EOF >/etc/logrotate.d/rsyslog
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

###############################################################################
# 165 – auditd instalado e rodando
###############################################################################
echo -e "\n[165] Instalar auditd e garantir execução"
if ! rpm -q audit &>/dev/null; then
    dnf install -y audit audit-libs
fi

# Evitar crash: garantir que auditd não está mascarado
systemctl unmask auditd &>/dev/null

systemctl enable auditd
systemctl start auditd 2>/dev/null || true

###############################################################################
# 166 – Auditoria antes do auditd (audit=1)
###############################################################################
echo -e "\n[166] Configurar GRUB com audit=1"
if ! grep -q 'audit=1' "$GRUB_FILE"; then
    sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="audit=1 /' "$GRUB_FILE"
    grub2-mkconfig -o /boot/grub2/grub.cfg
fi

###############################################################################
# 167 – Tamanho de armazenamento de audit log
###############################################################################
echo -e "\n[167] Ajustando max_log_file"
sed -i 's/^max_log_file.*/max_log_file = 50/' "$AUDITD"
grep -q '^max_log_file' "$AUDITD" || echo "max_log_file = 50" >> "$AUDITD"

###############################################################################
# 168 – Logs não excluídos automaticamente
###############################################################################
echo -e "\n[168] Configurar max_log_file_action"
sed -i 's/^max_log_file_action.*/max_log_file_action = rotate/' "$AUDITD"
grep -q '^max_log_file_action' "$AUDITD" || echo "max_log_file_action = rotate" >> "$AUDITD"

###############################################################################
# Preparação – garantir repositório de regras
###############################################################################
mkdir -p /etc/audit/rules.d
RULES="/etc/audit/rules.d/hardening.rules"
backup_file "$RULES"
touch "$RULES"

###############################################################################
# 169 – Auditoria de alterações em data/hora
###############################################################################
echo -e "\n[169] Auditoria de ajustes de data/hora"
grep -q adjtimex "$RULES" || cat <<EOF >> "$RULES"
-w /etc/localtime -p wa -k time-change
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
EOF

###############################################################################
# 170 – Auditoria de contas/grupos
###############################################################################
echo -e "\n[170] Auditoria de contas/grupos"
grep -q '/etc/passwd' "$RULES" || cat <<EOF >>"$RULES"
-w /etc/passwd   -p wa -k identity
-w /etc/shadow   -p wa -k identity
-w /etc/group    -p wa -k identity
-w /etc/gshadow  -p wa -k identity
EOF

###############################################################################
# 171 – Auditoria de rede
###############################################################################
echo -e "\n[171] Auditoria de rede"
grep -q 'sethostname' "$RULES" || cat <<EOF >>"$RULES"
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network-modify
-w /etc/hosts    -p wa -k network-modify
-w /etc/hostname -p wa -k network-modify
EOF

###############################################################################
# 172 – Auditoria MAC
###############################################################################
echo -e "\n[172] Auditoria de MAC"
grep -q 'MAC_POLICY_LOAD' "$RULES" || echo "-w /usr/share/selinux/ -p wa -k MAC_POLICY_LOAD" >> "$RULES"

###############################################################################
# 173 – Auditoria login/logout
###############################################################################
echo -e "\n[173] Auditoria de login/logout"
grep -q faillog "$RULES" || cat <<EOF >>"$RULES"
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/run/utmp    -p wa -k logins
EOF

###############################################################################
# 174 – Auditoria DAC
###############################################################################
echo -e "\n[174] Auditoria DAC"
grep -q chmod "$RULES" || echo "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k perm-modify" >> "$RULES"

###############################################################################
# 175 – Auditoria EACCES/EPERM
###############################################################################
echo -e "\n[175] Auditoria de acessos não autorizados"
grep -q EACCES "$RULES" || echo "-a always,exit -F arch=b64 -S open -S openat -F exit=-EACCES -k unauthorized" >> "$RULES"
grep -q EPERM  "$RULES" || echo "-a always,exit -F arch=b64 -S open -S openat -F exit=-EPERM  -k unauthorized" >> "$RULES"

###############################################################################
# 176 – Auditoria SUID
###############################################################################
echo -e "\n[176] Auditoria de SUID"
for f in $(find / -xdev -perm -4000 2>/dev/null); do
    grep -q "$f" "$RULES" || echo "-w $f -p x -k privileged" >> "$RULES"
done

###############################################################################
# 177 – Auditoria mount/unmount
###############################################################################
echo -e "\n[177] Auditoria mount/unmount"
grep -q mount "$RULES" || echo "-a always,exit -F arch=b64 -S mount -S umount2 -k mounts" >> "$RULES"

###############################################################################
# 178 – Auditoria deleção
###############################################################################
echo -e "\n[178] Auditoria de deleção"
grep -q unlink "$RULES" || echo "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete" >> "$RULES"

###############################################################################
# 179 – Auditoria kernel modules
###############################################################################
echo -e "\n[179] Auditoria de kernel modules"
grep -q init_module "$RULES" || echo "-a always,exit -F arch=b64 -S init_module -S finit_module -S delete_module -k modules" >> "$RULES"

###############################################################################
# 180 – Auditoria sudoers
###############################################################################
echo -e "\n[180] Auditoria de sudoers"
grep -q '/etc/sudoers' "$RULES"    || echo "-w /etc/sudoers      -p wa -k sudoers"  >> "$RULES"
grep -q '/etc/sudoers.d' "$RULES"  || echo "-w /etc/sudoers.d/    -p wa -k sudoers"  >> "$RULES"

###############################################################################
# 181 – Auditoria imutável (fix para não travar boot prematuramente)
###############################################################################
echo -e "\n[181] Configurar auditoria imutável"

# NÃO aplicar imutável antes de garantir que regras estão carregadas
grep -q '^-e 2' "$RULES" || echo "# Será ativado após carregamento completo das regras" >> "$RULES"

# Aplicar regras
augenrules --load &>/dev/null

# Ativar imutabilidade de forma segura
auditctl -e 2 &>/dev/null || true

systemctl restart auditd 2>/dev/null
