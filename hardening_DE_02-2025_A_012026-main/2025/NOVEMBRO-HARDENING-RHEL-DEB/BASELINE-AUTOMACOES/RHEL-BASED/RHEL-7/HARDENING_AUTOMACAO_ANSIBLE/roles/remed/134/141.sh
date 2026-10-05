#!/usr/bin/env bash
echo "[141–155] Remediação automática segura - Regras de auditoria (auditd rules)"

RULESDIR="/etc/audit/rules.d"
mkdir -p "$RULESDIR"

# 141 - Time change
echo "[141] Garantindo coleta de alterações de data e hora"
cat > "$RULESDIR/50-time-change.rules" <<'EOF'
-w /etc/localtime -p wa -k time-change
-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change
-a always,exit -F arch=b32 -S adjtimex,settimeofday,stime,clock_settime -k time-change
EOF
echo "✅ Regras de time-change aplicadas"

# 142 - Identity changes
echo "[142] Garantindo coleta de alterações de usuários e grupos"
cat > "$RULESDIR/50-identity.rules" <<'EOF'
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
EOF
echo "✅ Regras de identidade aplicadas"

# 143 - System locale / network env changes
echo "[143] Garantindo coleta de modificações no ambiente de rede e sistema"
cat > "$RULESDIR/50-system-locale.rules" <<'EOF'
-w /etc/issue -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale
-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale
EOF
echo "✅ Regras de system-locale aplicadas"

# 144 - MAC policy
echo "[144] Garantindo coleta de eventos de política MAC (SELinux)"
cat > "$RULESDIR/50-MAC-policy.rules" <<'EOF'
-w /etc/selinux/ -p wa -k MAC-policy
-w /usr/share/selinux/ -p wa -k MAC-policy
EOF
echo "✅ Regras de MAC-policy aplicadas"

# 145 - Logins
echo "[145] Garantindo coleta de eventos de login e logout"
cat > "$RULESDIR/50-logins.rules" <<'EOF'
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins
EOF
echo "✅ Regras de logins aplicadas"

# 146 - Session
echo "[146] Garantindo coleta de informações de sessão"
cat > "$RULESDIR/50-session.rules" <<'EOF'
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k logins
EOF
echo "✅ Regras de sessão aplicadas"

# 147 - Permission modification
echo "[147] Garantindo coleta de modificações de permissões de arquivos"
cat > "$RULESDIR/50-perm_mod.rules" <<'EOF'
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat,chown,fchown,fchownat,lchown,setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat,chown,fchown,fchownat,lchown,setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
EOF
echo "✅ Regras de perm_mod aplicadas"

# 148 - Access attempts
echo "[148] Garantindo coleta de tentativas de acesso não autorizadas"
cat > "$RULESDIR/50-access.rules" <<'EOF'
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
EOF
echo "✅ Regras de access aplicadas"

# 149 - Privileged commands
echo "[149] Garantindo coleta do uso de comandos privilegiados (SUID/SGID)"
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
{
  find /bin /sbin /usr/bin /usr/sbin -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null |
  while read -r bin; do
    echo "-a always,exit -F path=${bin} -F perm=x -F auid>=${UID_MIN} -F auid!=4294967295 -k privileged"
  done
} > "$RULESDIR/50-privileged.rules"
echo "✅ Regras de privileged aplicadas"


# 150 - Mount events
echo "[150] Garantindo coleta de montagens de sistemas de arquivos"
cat > "$RULESDIR/50-mounts.rules" <<'EOF'
-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts
-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts
EOF
echo "✅ Regras de mounts aplicadas"

# 151 - File deletions
echo "[151] Garantindo coleta de deleções de arquivos"
cat > "$RULESDIR/50-deletion.rules" <<'EOF'
-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=4294967295 -k delete
EOF
echo "✅ Regras de delete aplicadas"

# 152 - Sudoers modifications
echo "[152] Garantindo coleta de alterações no sudoers"
cat > "$RULESDIR/50-scope.rules" <<'EOF'
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope
EOF
echo "✅ Regras de scope aplicadas"

# 153 - Sudo command executions
echo "[153] Garantindo coleta de comandos via sudo"
cat > "$RULESDIR/50-actions.rules" <<'EOF'
-a always,exit -F arch=b64 -C euid!=uid -F euid=0 -F auid>=1000 -F auid!=4294967295 -S execve -k actions
-a always,exit -F arch=b32 -C euid!=uid -F euid=0 -F auid>=1000 -F auid!=4294967295 -S execve -k actions
EOF
echo "✅ Regras de sudo actions aplicadas"

# 154 - Kernel modules
echo "[154] Garantindo coleta de carregamento/descarregamento de módulos"
cat > "$RULESDIR/50-modules.rules" <<'EOF'
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module,delete_module -k modules
-a always,exit -F arch=b32 -S init_module,delete_module -k modules
EOF
echo "✅ Regras de modules aplicadas"

# 155 - Immutability
echo "[155] Configuração de imutabilidade das regras (manual)"
grep -q "^-e 2" "$RULESDIR"/* 2>/dev/null && echo "✅ Já configurado" || echo "⚠️ Manual — adicione '-e 2' ao final de /etc/audit/rules.d/99-finalize.rules"