#!/usr/bin/env bash
echo "[170 - 190] Configurações de módulos PAM"

PAM_FILES="/etc/pam.d/system-auth /etc/pam.d/password-auth"

PWQ_MAIN="/etc/security/pwquality.conf"
PWQ_DIR="/etc/security/pwquality.conf.d"
PWQ_ALL="$PWQ_MAIN $(ls -1 ${PWQ_DIR}/*.conf 2>/dev/null)"

FAILLOCK_MAIN="/etc/security/faillock.conf"
FAILLOCK_DIR="/etc/security/faillock.conf.d"
FAILLOCK_ALL="$FAILLOCK_MAIN $(ls -1 ${FAILLOCK_DIR}/*.conf 2>/dev/null)"

PWHIST_CONF="/etc/security/pwhistory.conf"

echo -e "\n [170] pam_faillock habilitado (auth/account)"
( egrep -i '^[[:space:]]*auth[[:space:]]+.*pam_faillock\.so' $PAM_FILES >/dev/null 2>&1 && \
  egrep -i '^[[:space:]]*account[[:space:]]+.*pam_faillock\.so' $PAM_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [171] pam_pwquality habilitado"
( egrep -i 'pam_pwquality\.so' $PAM_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [172] pam_pwhistory habilitado"
( egrep -i 'pam_pwhistory\.so' $PAM_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [173] pam_unix habilitado"
( egrep -i 'pam_unix\.so' $PAM_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [174] bloqueio por tentativas falhas (deny 1–5)"
( [ -n "$FAILLOCK_ALL" ] && egrep -i '^[[:space:]]*deny[[:space:]]*=[[:space:]]*[1-5]([[:space:]]|$)' $FAILLOCK_ALL >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [175] tempo de desbloqueio (unlock_time = 0 ou ≥900)"
( [ -n "$FAILLOCK_ALL" ] && egrep -i '^[[:space:]]*unlock_time[[:space:]]*=[[:space:]]*(0|9[0-9]{2}|[1-9][0-9]{3,})([[:space:]]|$)' $FAILLOCK_ALL >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [176] bloqueio inclui root (even_deny_root ou root_unlock_time ≥60)"
( [ -n "$FAILLOCK_ALL" ] && ( egrep -i '^[[:space:]]*even_deny_root([[:space:]]*=[[:space:]]*(1|yes|true))?([[:space:]]|$)' $FAILLOCK_ALL >/dev/null 2>&1 || \
                              egrep -i '^[[:space:]]*root_unlock_time[[:space:]]*=[[:space:]]*([6-9][0-9]|[1-9][0-9]{2,})([[:space:]]|$)' $FAILLOCK_ALL >/dev/null 2>&1 ) ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [177] difok ≥2"
( [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*difok[[:space:]]*=[[:space:]]*[2-9][0-9]*([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [178] minlen ≥14"
( [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*minlen[[:space:]]*=[[:space:]]*(1[4-9]|[2-9][0-9]{1,})([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [179] complexidade (minclass ≥4 OU u/l/d/o credit negativos)"
( [ -n "$PWQ_ALL" ] && ( egrep -i '^[[:space:]]*minclass[[:space:]]*=[[:space:]]*([4-9]|[1-9][0-9]+)([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1 || \
                         ( egrep -i '^[[:space:]]*ucredit[[:space:]]*=[[:space:]]*-[1-9][0-9]*' $PWQ_ALL >/dev/null 2>&1 && \
                           egrep -i '^[[:space:]]*lcredit[[:space:]]*=[[:space:]]*-[1-9][0-9]*' $PWQ_ALL >/dev/null 2>&1 && \
                           egrep -i '^[[:space:]]*dcredit[[:space:]]*=[[:space:]]*-[1-9][0-9]*' $PWQ_ALL >/dev/null 2>&1 && \
                           egrep -i '^[[:space:]]*ocredit[[:space:]]*=[[:space:]]*-[1-9][0-9]*' $PWQ_ALL >/dev/null 2>&1 ) ) ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [180] maxrepeat ≤3 (≠0)"
( [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*maxrepeat[[:space:]]*=[[:space:]]*[1-3]([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [181] maxsequence ≤3 (≠0)"
( [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*maxsequence[[:space:]]*=[[:space:]]*[1-3]([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [182] dictcheck habilitado (=1)"
( [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*dictcheck[[:space:]]*=[[:space:]]*1([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [183] enforce_for_root habilitado (pwquality)"
( [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*enforce_for_root([[:space:]]*=[[:space:]]*(1|yes|true))?([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [184] remember ≥24 (pwhistory)"
( [ -f "$PWHIST_CONF" ] && egrep -i '^[[:space:]]*remember[[:space:]]*=[[:space:]]*(2[4-9]|[3-9][0-9]|[1-9][0-9]{2,})([[:space:]]|$)' "$PWHIST_CONF" >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [185] enforce_for_root habilitado (pwhistory)"
( [ -f "$PWHIST_CONF" ] && egrep -i '^[[:space:]]*enforce_for_root([[:space:]]*=[[:space:]]*1)?([[:space:]]|$)' "$PWHIST_CONF" >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [186] pam_pwhistory usa use_authtok"
( egrep -i '^[[:space:]]*password[[:space:]]+.*pam_pwhistory\.so.*use_authtok' $PAM_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [187] pam_unix NÃO usa nullok"
( ! egrep -i '^[[:space:]]*(auth|account|password|session)[[:space:]]+(requisite|required|sufficient)[[:space:]]+pam_unix\.so.*\bnullok\b' $PAM_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [188] pam_unix NÃO usa remember=n"
( ! egrep -i '^[[:space:]]*password[[:space:]]+.*pam_unix\.so.*\bremember=[0-9]+\\b' $PAM_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [189] pam_unix usa hashing forte (sha512/yescrypt)"
( egrep -i '^[[:space:]]*password[[:space:]]+.*pam_unix\.so.*\b(sha512|yescrypt)\b' $PAM_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [190] pam_unix usa use_authtok"
( egrep -i '^[[:space:]]*password[[:space:]]+.*pam_unix\.so.*\buse_authtok\b' $PAM_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"