#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 148–164 (Contas, Shell, Sudo e Logs – RHEL 7)"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

############################################
# 148 – Apenas root com UID 0
############################################
echo -e "\n[148] UID 0 exclusivo"

awk -F: '($3==0 && $1!="root"){print $1}' /etc/passwd | while read u; do
  echo " ATENÇÃO: conta $u possui UID 0 – ajuste manualmente conforme baseline"
done

############################################
# 149 – Apenas grupo root com GID 0
############################################
echo -e "\n[149] GID 0 exclusivo"

awk -F: '($3==0 && $1!="root"){print $1}' /etc/group | while read g; do
  echo " ATENÇÃO: grupo $g possui GID 0 – ajuste manualmente conforme baseline"
done

############################################
# 150 – Contas sistema com shell inválido
############################################
echo -e "\n[150] Contas sistema sem shell interativo"

awk -F: '($3>0 && $3<1000 && $7!="/sbin/nologin" && $7!="/bin/false"){print $1}' /etc/passwd | while read u; do
  usermod -s /sbin/nologin "$u" >/dev/null 2>&1 || true
  echo " shell ajustado: $u"
done

############################################
# 151 – /etc/shells seguro
############################################
echo -e "\n[151] Ajustar /etc/shells"

backup /etc/shells
for sh in /bin/bash /bin/sh /sbin/nologin /bin/false; do
  grep -Fxq "$sh" /etc/shells 2>/dev/null || echo "$sh" >> /etc/shells
done

############################################
# 153 – umask restritiva
############################################
echo -e "\n[153] Umask padrão"

for f in /etc/profile /etc/bashrc; do
  backup "$f"
  if grep -q '^umask' "$f"; then
    sed -ri 's/^umask.*/umask 027/' "$f"
  else
    echo "umask 027" >> "$f"
  fi
done

############################################
# 154 – TMOUT
############################################
echo -e "\n[154] Timeout de shell"

for f in /etc/profile /etc/bashrc; do
  backup "$f"
  if ! grep -q '^TMOUT=' "$f"; then
    echo "TMOUT=900" >> "$f"
  fi
done

############################################
# 155–157–159 – SUDO
############################################
echo -e "\n[155–159] Hardening sudo"

backup /etc/sudoers

grep -q '^%wheel' /etc/sudoers || echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
grep -q '^Defaults requiretty' /etc/sudoers || echo "Defaults requiretty" >> /etc/sudoers
grep -q '^Defaults logfile=' /etc/sudoers || echo 'Defaults logfile="/var/log/sudo.log"' >> /etc/sudoers
grep -q '^Defaults timestamp_timeout=' /etc/sudoers || echo "Defaults timestamp_timeout=5" >> /etc/sudoers

############################################
# 160 – Restringir su a wheel
############################################
echo -e "\n[160] Restringir su a wheel"

# 1) Comenta linha trust se estiver ativa
sed -i 's/^auth[[:space:]]\+sufficient[[:space:]]\+pam_wheel\.so.*trust/#&/' /etc/pam.d/su

# 2) Garante a linha required se não existir ativa
if ! grep -q "^auth[[:space:]]\+required[[:space:]]\+pam_wheel\.so" /etc/pam.d/su; then
    echo "auth            required        pam_wheel.so use_uid" >> /etc/pam.d/su
fi

############################################
# 161–163 – Rsyslog
############################################
echo -e "\n[161–163] rsyslog"

if ! rpm -q rsyslog >/dev/null 2>&1; then
  yum -y install rsyslog >/dev/null 2>&1 || true
fi

systemctl enable --now rsyslog >/dev/null 2>&1 || true

############################################
# 162 – journald persistente
############################################
echo -e "\n[162] journald persistente"

backup /etc/systemd/journald.conf

if grep -q '^Storage=' /etc/systemd/journald.conf; then
  sed -ri 's/^Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
else
  echo "Storage=persistent" >> /etc/systemd/journald.conf
fi

systemctl restart systemd-journald >/dev/null 2>&1 || true

############################################
# 164 – logrotate
############################################
echo -e "\n[164] logrotate"

if ! grep -Eq '^\s*rotate\s+[1-9][0-9]*' /etc/logrotate.conf; then
  echo "rotate 12" >> /etc/logrotate.conf
fi

echo -e "\n[OK] Bloco 148–164 aplicado"
