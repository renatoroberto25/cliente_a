#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[169–180] Regras de auditoria (imune ao audit.rules)"

mkdir -p /etc/audit/rules.d

# Neutralizar /etc/audit/rules.d/audit.rules para não executar '-D'
AR="/etc/audit/rules.d/audit.rules"
if [ -f "$AR" ]; then
  cp -a "$AR" "$AR.bkp_$(date +%Y%m%d_%H%M%S)"
  mv "$AR" "${AR}.dist" || true
fi

RULES="/etc/audit/rules.d/hardening.rules"
[ -f "$RULES" ] && cp -a "$RULES" "$RULES.bkp_$(date +%Y%m%d_%H%M%S)"
: > "$RULES"

# 169 – alteração data/hora
echo '-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change' >> "$RULES"
echo '-a always,exit -F arch=b32 -S adjtimex,settimeofday,clock_settime -k time-change' >> "$RULES"

# 170 – contas/grupos
echo '-w /etc/passwd  -p wa -k identity'  >> "$RULES"
echo '-w /etc/group   -p wa -k identity'  >> "$RULES"
echo '-w /etc/shadow  -p wa -k identity'  >> "$RULES"
echo '-w /etc/gshadow -p wa -k identity'  >> "$RULES"

# 171 – rede
echo '-w /etc/sysconfig/network -p wa -k network' >> "$RULES"
echo '-w /etc/hosts -p wa -k network'               >> "$RULES"
echo '-w /etc/resolv.conf -p wa -k network'         >> "$RULES"

# 172 – SELinux
echo '-w /etc/selinux/ -p wa -k mac-policy' >> "$RULES"

# 173 – login/logout
echo '-w /var/log/wtmp    -p wa -k logins'  >> "$RULES"
echo '-w /var/log/btmp    -p wa -k logins'  >> "$RULES"
echo '-w /var/log/lastlog -p wa -k logins'  >> "$RULES"
echo '-w /var/run/faillock/ -p wa -k logins'>> "$RULES"

# 174 – permissões DAC
echo '-a always,exit -F arch=b64 -S chmod,chown,fchmod,fchmodat,setxattr,lsetxattr,fsetxattr -k perm_mod' >> "$RULES"
echo '-a always,exit -F arch=b32 -S chmod,chown,fchmod,fchmodat,setxattr,lsetxattr,fsetxattr -k perm_mod' >> "$RULES"

# 175 – tentativas de acesso negado
echo '-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EACCES -k access' >> "$RULES"
echo '-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EPERM  -k access' >> "$RULES"
echo '-a always,exit -F arch=b32 -S open,openat,creat -F exit=-EACCES -k access' >> "$RULES"
echo '-a always,exit -F arch=b32 -S open,openat,creat -F exit=-EPERM  -k access' >> "$RULES"

# 176 – execuções privilegiadas
echo '-a always,exit -F arch=b64 -S execve -F euid=0 -k privileged' >> "$RULES"
echo '-a always,exit -F arch=b32 -S execve -F euid=0 -k privileged' >> "$RULES"

# 177 – mount/unmount
echo '-a always,exit -F arch=b64 -S mount,umount2 -k mounts' >> "$RULES"
echo '-a always,exit -F arch=b32 -S mount,umount2 -k mounts' >> "$RULES"

# 178 – deleção de arquivos
echo '-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat,rmdir -k delete' >> "$RULES"
echo '-a always,exit -F arch=b32 -S unlink,unlinkat,rename,renameat,rmdir -k delete' >> "$RULES"

# 179 – módulos de kernel
echo '-a always,exit -F arch=b64 -S init_module,delete_module,finit_module -k modules' >> "$RULES"
echo '-a always,exit -F arch=b32 -S init_module,delete_module,finit_module -k modules' >> "$RULES"

# 180 – sudo e sudoers (RHEL7 costuma logar sudo em /var/log/secure)
echo '-w /etc/sudoers    -p wa -k scope'    >> "$RULES"
echo '-w /etc/sudoers.d/ -p wa -k scope'    >> "$RULES"
echo '-w /var/log/secure -p wa -k sudo'     >> "$RULES"

# Carregar regras
augenrules --load >/dev/null 2>&1 || true
systemctl restart auditd >/dev/null 2>&1 || true

echo "[OK] Regras 169–180 aplicadas"
