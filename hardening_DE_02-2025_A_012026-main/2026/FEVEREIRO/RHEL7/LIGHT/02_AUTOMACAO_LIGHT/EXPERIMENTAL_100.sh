#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[REMED-EXP] Hardening experimental p/ VM (itens: 35,36,40,41,42,88,124,172,173,183,187-190 + audit 169–180)"

# ==============================
# CONFIG RÁPIDA (ajuste por env)
# ==============================
: "${UPDATE_MODE:=full}"    # full | security-minimal
: "${BANNER_TXT:=USO RESTRITO. Acesso monitorado. Ao prosseguir, voce concorda com as politicas da empresa.}"
: "${FORCE_SUDO_LOG:=}"     # se =/var/log/sudo.log, força sudo a logar lá

timestamp() { date +%Y%m%d_%H%M%S; }
bk() { local f="$1"; [ -f "$f" ] && cp -a "$f" "$f.bkp_$(timestamp)"; }
append_unique_line() { local line="$1" file="$2"; grep -Fxq -- "$line" "$file" 2>/dev/null || echo "$line" >> "$file"; }

# =================================================
# 165–166: garantir auditd instalado/habilitado
# =================================================
echo -e "\n[165–166] auditd instalado/habilitado"
if ! rpm -q audit >/dev/null 2>&1; then yum -y install audit >/dev/null 2>&1; fi
systemctl enable auditd >/dev/null 2>&1 || true
systemctl start  auditd >/dev/null 2>&1 || true

# =================================================
# 167: ajuste básico de tamanho de log
# =================================================
echo -e "\n[167] Ajuste de max_log_file = 50"
AUDITD_CONF="/etc/audit/auditd.conf"; bk "$AUDITD_CONF"
grep -Eq '^[[:space:]]*max_log_file' "$AUDITD_CONF" \
  && sed -ri 's|^[[:space:]]*max_log_file.*|max_log_file = 50|' "$AUDITD_CONF" \
  || echo "max_log_file = 50" >> "$AUDITD_CONF"

# =================================================
# Neutralizar audit.rules com -D e aplicar 169–180
# =================================================
echo -e "\n[169–180] Neutralizar audit.rules e aplicar regras core"
mkdir -p /etc/audit/rules.d
AR="/etc/audit/rules.d/audit.rules"
if [ -f "$AR" ]; then bk "$AR"; mv "$AR" "${AR}.dist" || true; fi

RULES="/etc/audit/rules.d/hardening.rules"; bk "$RULES"; : > "$RULES"

# 169 – data/hora (b32/b64)
append_unique_line "-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change" "$RULES"
append_unique_line "-a always,exit -F arch=b32 -S adjtimex,settimeofday,clock_settime -k time-change" "$RULES"

# 170 – contas/grupos
append_unique_line "-w /etc/passwd  -p wa -k identity"  "$RULES"
append_unique_line "-w /etc/group   -p wa -k identity"  "$RULES"
append_unique_line "-w /etc/shadow  -p wa -k identity"  "$RULES"
append_unique_line "-w /etc/gshadow -p wa -k identity"  "$RULES"

# 171 – rede
append_unique_line "-w /etc/sysconfig/network -p wa -k network" "$RULES"
append_unique_line "-w /etc/hosts -p wa -k network"               "$RULES"
append_unique_line "-w /etc/resolv.conf -p wa -k network"         "$RULES"

# 172 – MAC/SELinux
append_unique_line "-w /etc/selinux/ -p wa -k mac-policy" "$RULES"

# 173 – login/logout
append_unique_line "-w /var/log/wtmp     -p wa -k logins"  "$RULES"
append_unique_line "-w /var/log/btmp     -p wa -k logins"  "$RULES"
append_unique_line "-w /var/log/lastlog  -p wa -k logins"  "$RULES"
append_unique_line "-w /var/run/faillock/ -p wa -k logins" "$RULES"

# 174 – DAC (b32/b64)
append_unique_line "-a always,exit -F arch=b64 -S chmod,chown,fchmod,fchmodat,setxattr,lsetxattr,fsetxattr -k perm_mod" "$RULES"
append_unique_line "-a always,exit -F arch=b32 -S chmod,chown,fchmod,fchmodat,setxattr,lsetxattr,fsetxattr -k perm_mod" "$RULES"

# 175 – acesso negado (b32/b64)
append_unique_line "-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EACCES -k access" "$RULES"
append_unique_line "-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EPERM  -k access" "$RULES"
append_unique_line "-a always,exit -F arch=b32 -S open,openat,creat -F exit=-EACCES -k access" "$RULES"
append_unique_line "-a always,exit -F arch=b32 -S open,openat,creat -F exit=-EPERM  -k access" "$RULES"

# 176 – execuções privilegiadas
append_unique_line "-a always,exit -F arch=b64 -S execve -F euid=0 -k privileged" "$RULES"
append_unique_line "-a always,exit -F arch=b32 -S execve -F euid=0 -k privileged" "$RULES"

# 177 – mount/unmount
append_unique_line "-a always,exit -F arch=b64 -S mount,umount2 -k mounts" "$RULES"
append_unique_line "-a always,exit -F arch=b32 -S mount,umount2 -k mounts" "$RULES"

# 178 – deleção
append_unique_line "-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat,rmdir -k delete" "$RULES"
append_unique_line "-a always,exit -F arch=b32 -S unlink,unlinkat,rename,renameat,rmdir -k delete" "$RULES"

# 179 – módulos kernel
append_unique_line "-a always,exit -F arch=b64 -S init_module,delete_module,finit_module -k modules" "$RULES"
append_unique_line "-a always,exit -F arch=b32 -S init_module,delete_module,finit_module -k modules" "$RULES"

# 180 – sudo/sudoers
append_unique_line "-w /etc/sudoers    -p wa -k scope" "$RULES"
append_unique_line "-w /etc/sudoers.d/ -p wa -k scope" "$RULES"
if [ -n "${FORCE_SUDO_LOG:-}" ]; then
  # força sudo.log explicitamente
  bk /etc/sudoers
  if ! grep -Eq '^\s*Defaults\s+logfile=' /etc/sudoers; then
    echo "Defaults logfile=\"${FORCE_SUDO_LOG}\"" >> /etc/sudoers
  else
    sed -ri "s#^\s*Defaults\s+logfile=.*#Defaults logfile=\"${FORCE_SUDO_LOG}\"#" /etc/sudoers
  fi
  append_unique_line "-w ${FORCE_SUDO_LOG} -p wa -k sudo" "$RULES"
else
  append_unique_line "-w /var/log/secure -p wa -k sudo" "$RULES"
fi

augenrules --load >/dev/null 2>&1 || true
systemctl restart auditd >/dev/null 2>&1 || true

# =================================================
# 35/36/40/41/42: fstab - aplicar options se entrada existir
# (Só se já houver partição/entrada no fstab. Não cria partições.)
# =================================================
echo -e "\n[35/36/40/41/42] fstab: aplicar nodev/nosuid/noexec (onde aplicável)"

FSTAB="/etc/fstab"; bk "$FSTAB"

# helper p/ inserir opções numa linha do fstab do mountpoint exato
add_opt_mountpoint() {
  local mnt="$1" add_opts="$2"
  awk -v mnt="$mnt" -v add="$add_opts" '
    BEGIN{OFS="\t"}
    $0 ~ /^[[:space:]]*#/ {print; next}
    NF>=4 && $2==mnt {
      split($4, a, ",")
      # construir set de opções (evitar duplicata)
      opts=$4
      n=split(add, b, ",")
      for(i=1;i<=n;i++){
        o=b[i]
        if (opts !~ "(^|,)" o "(,|$)") opts = opts "," o
      }
      $4=opts
      print; next
    }
    {print}
  ' "$FSTAB" > "${FSTAB}.tmp" && mv "${FSTAB}.tmp" "$FSTAB"
}

# 35: mídias removíveis (heurística: entradas para /media/* ou /mnt/*)
# aplica nodev,nosuid,noexec
if grep -Eq '^[^#].*\s/(media|mnt)/' "$FSTAB"; then
  while read -r m; do
    mp=$(echo "$m" | awk '{print $2}')
    add_opt_mountpoint "$mp" "nodev,nosuid,noexec"
    mountpoint -q "$mp" && mount -o remount "$mp" || true
  done < <(grep -E '^[^#].*\s/(media|mnt)/' "$FSTAB" || true)
fi

# 36/40/41/42: partições críticas (só se existirem no fstab)
for MP in /tmp /var/tmp /home /var /var/log /var/log/audit /dev/shm; do
  if grep -Eq "^[^#].*[[:space:]]$MP[[:space:]]" "$FSTAB"; then
    case "$MP" in
      /home) ADD="nodev" ;;
      /var|/var/log|/var/log/audit) ADD="nodev,nosuid" ;;
      /tmp|/var/tmp|/dev/shm) ADD="nodev,nosuid,noexec" ;;
      *) ADD="nodev,nosuid" ;;
    esac
    add_opt_mountpoint "$MP" "$ADD"
    mountpoint -q "$MP" && mount -o remount "$MP" || true
  fi
done

# =================================================
# 88: atualizações de segurança
# =================================================
echo -e "\n[88] Atualizações (${UPDATE_MODE})"
yum clean all >/dev/null 2>&1 || true
case "$UPDATE_MODE" in
  security-minimal) yum -y --security update-minimal || yum -y --security update ;;
  *)                yum -y update ;;
esac

# =================================================
# 124: banner legal + SSH Banner
# =================================================
echo -e "\n[124] Banner legal"
bk /etc/issue; bk /etc/issue.net; bk /etc/ssh/sshd_config
printf '%s\n' "$BANNER_TXT" | tee /etc/issue /etc/issue.net >/dev/null
if grep -Eq '^\s*Banner\s+' /etc/ssh/sshd_config; then
  sed -ri 's#^\s*Banner\s+.*#Banner /etc/issue.net#' /etc/ssh/sshd_config
else
  echo 'Banner /etc/issue.net' >> /etc/ssh/sshd_config
fi
systemctl reload sshd >/dev/null 2>&1 || systemctl restart sshd >/devnull 2>&1 || true

# =================================================
# 183: integridade (AIDE diário 04:00)
# =================================================
echo -e "\n[183] AIDE agendado"
if ! rpm -q aide >/dev/null 2>&1; then yum -y install aide >/dev/null 2>&1; fi
aide --init || true
[ -f /var/lib/aide/aide.db.new.gz ] && mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz || true
echo '0 4 * * * root /usr/sbin/aide --check || logger -t AIDE "integrity check failed"' > /etc/cron.d/aide-check

# =================================================
# 187–190: permissões shadow/gshadow
# =================================================
echo -e "\n[187–190] Ajuste de permissões sensíveis"
for f in /etc/shadow /etc/shadow- /etc/gshadow /etc/gshadow-; do
  [ -e "$f" ] || continue
  chown root:root "$f" || true
done
# baseline mais restritivo (000) — comum em RHEL/OL7
chmod 000 /etc/shadow  2>/dev/null || true
chmod 000 /etc/shadow- 2>/dev/null || true
chmod 000 /etc/gshadow 2>/dev/null || true
chmod 000 /etc/gshadow- 2>/dev/null || true

# ==============================
# CHECK RÁPIDO
# ==============================
echo -e "\n[CHECK] auditctl -l (amostra)"
auditctl -l 2>/dev/null | egrep -i 'time-change|identity|network|mac-policy|logins|perm_mod|access|privileged|mounts|delete|modules|sudo' || true

echo -e "\n[DONE] REMED-EXP aplicado. Reboot recomendado se fstab alterado."