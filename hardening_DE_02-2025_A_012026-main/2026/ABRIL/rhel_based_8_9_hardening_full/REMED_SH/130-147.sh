#!/usr/bin/env bash

backup_file() {
    [ -f "$1" ] && cp "$1" "$1.bak_$(date +%F-%H%M%S)"
}

########################################
# 130 e 131 – pam_pwquality habilitado E CONFIGURADO
########################################
echo -e "\n[130 - 131] Remediação pam_pwquality"

backup_file /etc/security/pwquality.conf

if ! grep -Eq 'pam_pwquality\.so' /etc/pam.d/system-auth 2>/dev/null; then
    backup_file /etc/pam.d/system-auth
    sed -i '/pam_unix\.so/i password    requisite     pam_pwquality.so retry=3' /etc/pam.d/system-auth
fi

if ! grep -Eq 'pam_pwquality\.so' /etc/pam.d/password-auth 2>/dev/null; then
    backup_file /etc/pam.d/password-auth
    sed -i '/pam_unix\.so/i password    requisite     pam_pwquality.so retry=3' /etc/pam.d/password-auth
fi

if grep -Eq '^[[:space:]]*minlen[[:space:]]*=' /etc/security/pwquality.conf; then
    sed -ri 's|^[[:space:]]*minlen[[:space:]]*=.*|minlen = 14|' /etc/security/pwquality.conf
else
    echo 'minlen = 14' >> /etc/security/pwquality.conf
fi

if grep -Eq '^[[:space:]]*minclass[[:space:]]*=' /etc/security/pwquality.conf; then
    sed -ri 's|^[[:space:]]*minclass[[:space:]]*=.*|minclass = 4|' /etc/security/pwquality.conf
else
    echo 'minclass = 4' >> /etc/security/pwquality.conf
fi

##############################################################
# 132 – pam_faillock habilitado (RECOMENTAÇÃO: AJUSTE MANUAL)
##############################################################
#echo -e "\n[132] Remediação: pam_faillock habilitado (via authselect)"
## Verifica se já está com perfil com faillock
#if ! authselect current | grep -q with-faillock; then
#    echo "→ Habilitando perfil 'sssd with-faillock'"
#    authselect select sssd with-faillock --force
#    echo "✔ Perfil 'sssd with-faillock' aplicado"
#else
#    echo "✔ pam_faillock já habilitado no authselect"
#fi

##############################################################
# 133 – pam_tally2 (LEGADO - RECOMENTAÇÃO: AJUSTE MANUAL)
##############################################################
#echo -e "\n[133] Remediação: pam_tally2 habilitado (somente se usado no ambiente)"
#if ! grep -Eq 'pam_tally2\.so' /etc/pam.d/system-auth; then
#    backup_file /etc/pam.d/system-auth
#    sed -i '/pam_unix\.so/i auth required pam_tally2.so deny=5 unlock_time=900' /etc/pam.d/system-auth
#fi

########################################
# 134 – pam_pwhistory
########################################
echo -e "\n[134] Remediação: pam_pwhistory habilitado"
for f in /etc/pam.d/system-auth /etc/pam.d/password-auth; do
    if ! grep -q 'pam_pwhistory.so' "$f"; then
        sed -i '/pam_unix\.so/i password required pam_pwhistory.so remember=5' "$f"
    fi
done
########################################
# 135 – minlen ≥ 14
########################################
echo -e "\n[135] Remediação: minlen ≥ 14"

backup_file /etc/security/pwquality.conf
grep -Eq '^minlen' /etc/security/pwquality.conf && \
    sed -i 's/^minlen.*/minlen = 14/' /etc/security/pwquality.conf || \
    echo "minlen = 14" >> /etc/security/pwquality.conf
########################################
# 136 – minclass ≥ 4
########################################
echo -e "\n[136] Remediação: minclass ≥ 4"
backup_file /etc/security/pwquality.conf
grep -Eq '^minclass' /etc/security/pwquality.conf && \
    sed -i 's/^minclass.*/minclass = 4/' /etc/security/pwquality.conf || \
    echo "minclass = 4" >> /etc/security/pwquality.conf

########################################
# 137 – maxrepeat / maxsequence
########################################
echo -e "\n[137] Remediação: maxrepeat=3, maxsequence=3"
backup_file /etc/security/pwquality.conf
sed -i '/^maxrepeat/d' /etc/security/pwquality.conf
sed -i '/^maxsequence/d' /etc/security/pwquality.conf
echo "maxrepeat = 3" >> /etc/security/pwquality.conf
echo "maxsequence = 3" >> /etc/security/pwquality.conf
########################################
# 138 – dictcheck != 0
########################################
echo -e "\n[138] Remediação: dictcheck != 0"
backup_file /etc/security/pwquality.conf
sed -i 's/^dictcheck\s*=.*/dictcheck = 1/' /etc/security/pwquality.conf
grep -q '^dictcheck' /etc/security/pwquality.conf || echo "dictcheck = 1" >> /etc/security/pwquality.conf
########################################
# 139 – hashing forte (sha512/yescrypt)
########################################
echo "[139] Remediação: Hashing forte de senhas"
if grep -q "release 9" /etc/redhat-release 2>/dev/null; then
    ALGO="YESCRYPT"
else
    ALGO="SHA512"
fi
backup_file /etc/login.defs
if grep -Eq '^[[:space:]]*ENCRYPT_METHOD[[:space:]]+' /etc/login.defs; then
    sed -ri "s|^[[:space:]]*ENCRYPT_METHOD[[:space:]]+.*|ENCRYPT_METHOD $ALGO|" /etc/login.defs
else
    echo "ENCRYPT_METHOD $ALGO" >> /etc/login.defs
fi
authselect apply-changes -b >/dev/null 2>&1 || true

########################################
# 140 – remember ≥ 5
########################################
echo -e "\n[140] Remediação: remember ≥ 5"
for f in /etc/pam.d/system-auth /etc/pam.d/password-auth; do
    if grep -q 'pam_pwhistory\.so' "$f"; then
        sed -ri 's/(pam_pwhistory\.so.*)remember=[0-9]+/\1remember=5/' "$f"
        grep -q 'remember=' "$f" || sed -ri 's/(pam_pwhistory\.so.*)/\1 remember=5/' "$f"
    fi
done

########################################
# 141 – deny ≥ 5 (faillock.conf)
########################################
echo -e "\n[141] Remediação: deny ≥ 5"

backup_file /etc/security/faillock.conf
sed -i 's/^deny.*/deny = 5/' /etc/security/faillock.conf
grep -q '^deny' /etc/security/faillock.conf || echo "deny = 5" >> /etc/security/faillock.conf


########################################
# 142 – unlock_time ≥ 900
########################################
echo -e "\n[142] Remediação: unlock_time ≥ 900"

backup_file /etc/security/faillock.conf
sed -i 's/^unlock_time.*/unlock_time = 900/' /etc/security/faillock.conf
grep -q '^unlock_time' /etc/security/faillock.conf || echo "unlock_time = 900" >> /etc/security/faillock.conf


################################################################################
# 143 – PASS_MAX_DAYS ≤ 365 - 144 – PASS_MIN_DAYS ≥ 1 - 145 – PASS_WARN_AGE ≥ 7
################################################################################
backup_file /etc/login.defs

echo -e "\n[143] PASS_MAX_DAYS ≤ 365"
if grep -Eq '^PASS_MAX_DAYS[[:space:]]+' /etc/login.defs; then
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   365/' /etc/login.defs
else
    echo "PASS_MAX_DAYS   365" >> /etc/login.defs
fi

echo -e "\n[144] PASS_MIN_DAYS ≥ 1"
if grep -Eq '^PASS_MIN_DAYS[[:space:]]+' /etc/login.defs; then
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
else
    echo "PASS_MIN_DAYS   1" >> /etc/login.defs
fi

echo -e "\n[145] PASS_WARN_AGE ≥ 7"
if grep -Eq '^PASS_WARN_AGE[[:space:]]+' /etc/login.defs; then
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs
else
    echo "PASS_WARN_AGE   7" >> /etc/login.defs
fi

########################################
# 146 – inactive ≥ 30
########################################
echo -e "\n[146] Remediação: inactive ≥ 30"
awk -F: '$2~/^\$/{print $1}' /etc/shadow | while read -r user; do
    chage --inactive 30 "$user"
done


########################################
# 147 – campo 3 != 0 ou vazio
########################################
echo -e "\n[147] Remediação: data última troca válida"

for user in $(awk -F: '$2~/^\$/{print $1}' /etc/shadow); do
    lastchg=$(awk -F: -v u="$user" '$1==u{print $3}' /etc/shadow)
    if [ -z "$lastchg" ] || [ "$lastchg" -eq 0 ]; then
        chage --lastday 1 "$user"
    fi
done

echo "OK"
exit 0
