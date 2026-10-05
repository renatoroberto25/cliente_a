#!/usr/bin/env bash

# Backup simples
backup_file() {
    [ -f "$1" ] && cp "$1" "$1.bak_$(date +%F-%H%M%S)"
}

########################################
# 135 – minlen ≥ 14
# OK #Ajuste somente no pwquality.conf
########################################
echo -e "\n[135] Remediação: minlen ≥ 14"

backup_file /etc/security/pwquality.conf
grep -Eq '^minlen' /etc/security/pwquality.conf && \
    sed -i 's/^minlen.*/minlen = 14/' /etc/security/pwquality.conf || \
    echo "minlen = 14" >> /etc/security/pwquality.conf


########################################
# 136 – minclass ≥ 4
# OK #Também pwquality.conf, seguro
########################################
echo -e "\n[136] Remediação: minclass ≥ 4"

backup_file /etc/security/pwquality.conf
grep -Eq '^minclass' /etc/security/pwquality.conf && \
    sed -i 's/^minclass.*/minclass = 4/' /etc/security/pwquality.conf || \
    echo "minclass = 4" >> /etc/security/pwquality.conf


########################################
# 137 – maxrepeat / maxsequence
# OK #Apenas regras do pwquality.conf
########################################
echo -e "\n[137] Remediação: maxrepeat=3, maxsequence=3"

backup_file /etc/security/pwquality.conf
sed -i '/^maxrepeat/d' /etc/security/pwquality.conf
sed -i '/^maxsequence/d' /etc/security/pwquality.conf
echo "maxrepeat = 3" >> /etc/security/pwquality.conf
echo "maxsequence = 3" >> /etc/security/pwquality.conf


########################################
# 138 – dictcheck != 0
# OK #Sem impacto em PAM, apenas pwquality.conf
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
# OK #Ajusta somente pwhistory existente; não adiciona módulo
########################################
echo -e "\n[140] Remediação: remember ≥ 5"

backup_file /etc/pam.d/system-auth
sed -i '/pam_pwhistory\.so/ s/remember=[0-9]\+/remember=5/' /etc/pam.d/system-auth


########################################
# 141 – deny ≥ 5
# OK #faillock.conf é isolado, não interfere no PAM stack
########################################
echo -e "\n[141] Remediação: deny ≥ 5"

backup_file /etc/security/faillock.conf
sed -i 's/^deny.*/deny = 5/' /etc/security/faillock.conf
grep -q '^deny' /etc/security/faillock.conf || echo "deny = 5" >> /etc/security/faillock.conf


########################################
# 142 – unlock_time ≥ 900
# OK #Também seguro no faillock.conf
########################################
echo -e "\n[142] Remediação: unlock_time ≥ 900"

backup_file /etc/security/faillock.conf
sed -i 's/^unlock_time.*/unlock_time = 900/' /etc/security/faillock.conf
grep -q '^unlock_time' /etc/security/faillock.conf || echo "unlock_time = 900" >> /etc/security/faillock.conf


########################################
# 143 – PASS_MAX_DAYS ≤ 365
# OK #login.defs não altera funcionamento do PAM, apenas aging
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
# OK #chage ajusta aging, não mexe em PAM
########################################
echo -e "\n[146] Remediação: inactive ≥ 30"

for user in $(awk -F: '$2~/^\$/{print $1}' /etc/shadow); do
    chage --inactive 30 "$user"
done


########################################
# 147 – campo 3 != 0 ou vazio
# OK #Ajuste de aging, totalmente seguro
########################################
echo -e "\n[147] Remediação: data última troca válida"

for user in $(awk -F: '$2~/^\$/{print $1}' /etc/shadow); do
    lastchg=$(awk -F: -v u="$user" '$1==u{print $3}' /etc/shadow)
    if [ -z "$lastchg" ] || [ "$lastchg" -eq 0 ]; then
        chage --lastday 1 "$user"
    fi
done

#130 — Inserir pam_pwquality no system-auth
#Não pode automatizar, pois corrompe authselect.

#132 — authselect with-faillock
#Troca o perfil do sistema à força #risco de outage.

#133 — pam_tally2
#Conflitante com faillock. Aplicável apenas em algumas versões antigas.

#134 — inserir pam_pwhistory no PAM
#Módulos tem que ser incluídos manualmente, grande risco de perca de login.

#139 — sobrescrever pam_unix.so
#Nunca deve ser sedado diretamente.