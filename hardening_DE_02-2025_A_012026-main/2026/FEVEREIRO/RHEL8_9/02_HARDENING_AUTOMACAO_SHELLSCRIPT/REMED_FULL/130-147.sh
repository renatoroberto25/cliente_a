#!/usr/bin/env bash

backup_file() {
    [ -f "$1" ] && cp "$1" "$1.bak_$(date +%F-%H%M%S)"
}

########################################
# 130 e 13 – pam_pwquality habilitado
########################################
echo -e "\n[130/13] Remediação: pam_pwquality habilitado"

if ! grep -Eq 'pam_pwquality\.so' /etc/pam.d/system-auth; then
    backup_file /etc/pam.d/system-auth
    sed -i '/pam_unix\.so/i password    requisite     pam_pwquality.so retry=3' /etc/pam.d/system-auth
fi

if ! grep -Eq 'pam_pwquality\.so' /etc/pam.d/password-auth; then
    backup_file /etc/pam.d/password-auth
    sed -i '/pam_unix\.so/i password    requisite     pam_pwquality.so retry=3' /etc/pam.d/password-auth
fi

########################################
# 132 – pam_faillock habilitado (modo seguro)
########################################
echo -e "\n[132] Remediação: pam_faillock habilitado (via authselect)"

# Verifica se já está com perfil com faillock
if ! authselect current | grep -q with-faillock; then
    echo "→ Habilitando perfil 'sssd with-faillock'"
    authselect select sssd with-faillock --force
    echo "✔ Perfil 'sssd with-faillock' aplicado"
else
    echo "✔ pam_faillock já habilitado no authselect"
fi

########################################
# 133 – pam_tally2 (legacy)
########################################
echo -e "\n[133] Remediação: pam_tally2 habilitado (somente se usado no ambiente)"

if ! grep -Eq 'pam_tally2\.so' /etc/pam.d/system-auth; then
    backup_file /etc/pam.d/system-auth
    sed -i '/pam_unix\.so/i auth required pam_tally2.so deny=5 unlock_time=900' /etc/pam.d/system-auth
fi


########################################
# 134 – pam_pwhistory
########################################
echo -e "\n[134] Remediação: pam_pwhistory habilitado"

if ! grep -Eq 'pam_pwhistory\.so' /etc/pam.d/system-auth; then
    backup_file /etc/pam.d/system-auth
    sed -i '/pam_unix\.so/i password required pam_pwhistory.so remember=5' /etc/pam.d/system-auth
fi


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
echo "[139] Remediação FULL: Hash forte SHA512/Yescrypt"

PROFILE="custom/hitss"
BASE="/etc/authselect/${PROFILE}"

# Garante que existe perfil custom
if ! authselect current | grep -q "$PROFILE"; then
    echo "→ Criando perfil custom HITSS baseado em sssd"
    authselect create-profile hitss -b sssd
fi

# Função para ajustar arquivo template do perfil
fix_pam_unix() {
    local file="$1"

    if grep -Eq 'pam_unix\.so.*(sha512|yescrypt)' "$file"; then
        echo "✔ Hash forte já presente em $file"
        return
    fi

    echo "→ Ajustando hash forte em $file"
    sed -ri 's/(pam_unix\.so)(.*)/\1 sha512 shadow\2/' "$file"
}

# Ajuste nos templates
fix_pam_unix "$BASE/system-auth"
fix_pam_unix "$BASE/password-auth"

# Reaplica o perfil
echo "→ Aplicando perfil custom HITSS"
authselect select $PROFILE --force
authselect apply-changes


########################################
# 140 – remember ≥ 5
########################################
echo -e "\n[140] Remediação: remember ≥ 5"

backup_file /etc/pam.d/system-auth
sed -i '/pam_pwhistory\.so/ s/remember=[0-9]\+/remember=5/' /etc/pam.d/system-auth


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


########################################
# 143 – PASS_MAX_DAYS ≤ 365
########################################
echo -e "\n[143] PASS_MAX_DAYS ≤ 365"

backup_file /etc/login.defs
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   365/' /etc/login.defs


########################################
# 144 – PASS_MIN_DAYS ≥ 1
########################################
echo -e "\n[144] PASS_MIN_DAYS ≥ 1"

backup_file /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs


########################################
# 145 – PASS_WARN_AGE ≥ 7
########################################
echo -e "\n[145] PASS_WARN_AGE ≥ 7"

backup_file /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs


########################################
# 146 – inactive ≥ 30
########################################
echo -e "\n[146] Remediação: inactive ≥ 30"

for user in $(awk -F: '$2~/^\$/{print $1}' /etc/shadow); do
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
