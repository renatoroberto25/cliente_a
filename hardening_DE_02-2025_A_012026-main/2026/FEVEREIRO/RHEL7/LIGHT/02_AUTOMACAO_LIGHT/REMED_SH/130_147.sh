#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 130–147 (PAM e Política de Senhas – RHEL 7)"

SYSTEM_AUTH="/etc/pam.d/system-auth"
PWQUALITY="/etc/security/pwquality.conf"
LOGIN_DEFS="/etc/login.defs"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

backup "$SYSTEM_AUTH"
backup "$PWQUALITY"
backup "$LOGIN_DEFS"

############################################
# 130–136 – pam_pwquality
############################################
echo -e "\n[130–136] pam_pwquality"

if ! grep -Eq '\bpam_pwquality\.so\b' "$SYSTEM_AUTH"; then
  sed -ri '/^password.*sufficient.*pam_unix\.so/i password    requisite     pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1' "$SYSTEM_AUTH"
fi

sed -ri 's|(pam_pwquality\.so.*)|pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1|' "$SYSTEM_AUTH"

############################################
# 134 / 140 – pam_pwhistory
############################################
echo -e "\n[134–140] pam_pwhistory"

if ! grep -Eq '\bpam_pwhistory\.so\b' "$SYSTEM_AUTH"; then
  sed -ri '/^password.*sufficient.*pam_unix\.so/i password    required     pam_pwhistory.so remember=5 use_authtok' "$SYSTEM_AUTH"
fi

sed -ri 's|(pam_pwhistory\.so.*)|pam_pwhistory.so remember=5 use_authtok|' "$SYSTEM_AUTH"

############################################
# 137–138 – pwquality.conf
############################################
echo -e "\n[137–138] pwquality.conf"

grep -q '^maxrepeat' "$PWQUALITY" 2>/dev/null && \
  sed -ri 's/^maxrepeat.*/maxrepeat = 3/' "$PWQUALITY" || \
  echo "maxrepeat = 3" >> "$PWQUALITY"

grep -q '^maxsequence' "$PWQUALITY" 2>/dev/null && \
  sed -ri 's/^maxsequence.*/maxsequence = 3/' "$PWQUALITY" || \
  echo "maxsequence = 3" >> "$PWQUALITY"

grep -q '^dictcheck' "$PWQUALITY" 2>/dev/null && \
  sed -ri 's/^dictcheck.*/dictcheck = 1/' "$PWQUALITY" || \
  echo "dictcheck = 1" >> "$PWQUALITY"

############################################
# 139 – sha512
############################################
echo -e "\n[139] Hashing forte (sha512)"

sed -ri 's|^(password[[:space:]]+[^[:space:]]+[[:space:]]+pam_unix\.so).*|\1 sha512 shadow try_first_pass use_authtok|' "$SYSTEM_AUTH"

############################################
# 142 – pam_faillock
############################################
echo -e "\n[142] pam_faillock"

if ! grep -Eq '\bpam_faillock\.so\b' "$SYSTEM_AUTH"; then
  sed -ri '/^auth.*required.*pam_env\.so/a auth        required      pam_faillock.so preauth silent deny=5 unlock_time=900' "$SYSTEM_AUTH"
  sed -ri '/^auth.*sufficient.*pam_unix\.so/a auth        [default=die] pam_faillock.so authfail deny=5 unlock_time=900' "$SYSTEM_AUTH"
fi

############################################
# 143–145 – login.defs
############################################
echo -e "\n[143–145] login.defs"

sed -ri 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' "$LOGIN_DEFS" || true
grep -q '^PASS_MAX_DAYS' "$LOGIN_DEFS" || echo "PASS_MAX_DAYS   90" >> "$LOGIN_DEFS"

sed -ri 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' "$LOGIN_DEFS" || true
grep -q '^PASS_MIN_DAYS' "$LOGIN_DEFS" || echo "PASS_MIN_DAYS   1" >> "$LOGIN_DEFS"

sed -ri 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' "$LOGIN_DEFS" || true
grep -q '^PASS_WARN_AGE' "$LOGIN_DEFS" || echo "PASS_WARN_AGE   7" >> "$LOGIN_DEFS"

############################################
# 146 – INACTIVE
############################################
echo -e "\n[146] INACTIVE padrão"

useradd -D -f 30

############################################
# 147 – Corrigir shadow inconsistências
############################################]
echo -e "\n[147] Corrigir datas inconsistentes"

awk -F: '($2!~/^(!|\*)/ && $2!="" && $5==0){print $1}' /etc/shadow | while read u; do
  chage --maxdays 90 "$u" >/dev/null 2>&1 || true
done

echo -e "\n[OK] Bloco 130–147 aplicado"
