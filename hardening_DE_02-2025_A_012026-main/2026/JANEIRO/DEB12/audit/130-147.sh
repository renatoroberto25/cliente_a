#!/usr/bin/env bash

echo -e "\n[130] pwquality habilitado (Debian: common-password)"
grep -Eq '^[[:space:]]*password[[:space:]]+.*pam_pwquality\.so\b' /etc/pam.d/common-password 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[132] pam_faillock habilitado (Debian: common-auth/common-account)"
( grep -Eq 'pam_faillock\.so\b' /etc/pam.d/common-auth /etc/pam.d/common-account 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[133] pam_tally2 NÃO deve existir (Debian 12: N/A, manter como ausência)"
! grep -REq 'pam_tally2\.so\b' /etc/pam.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#ADAPTAR NO BASELINE

echo -e "\n[134] pam_pwhistory habilitado (Debian: common-password)"
grep -Eq '^[[:space:]]*password[[:space:]]+.*pam_pwhistory\.so\b' /etc/pam.d/common-password 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[135] minlen ≥ 14 (pwquality.conf e pwquality.conf.d)"
cat /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null | grep -Eiq '^[[:space:]]*minlen[[:space:]]*=[[:space:]]*(1[4-9]|[2-9][0-9]+)\b' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[136] minclass ≥ 4 (pwquality.conf e pwquality.conf.d)"
cat /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null | grep -Eiq '^[[:space:]]*minclass[[:space:]]*=[[:space:]]*[4-9]\b' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[137] maxrepeat & maxsequence = 3 (pwquality.conf e pwquality.conf.d)"
( cat /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null | grep -Eiq '^[[:space:]]*maxrepeat[[:space:]]*=[[:space:]]*3\b' && cat /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null | grep -Eiq '^[[:space:]]*maxsequence[[:space:]]*=[[:space:]]*3\b' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[138] dictcheck != 0 (pwquality.conf e pwquality.conf.d)"
! cat /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null | grep -Eiq '^[[:space:]]*dictcheck[[:space:]]*=[[:space:]]*0\b' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[139] Hashing sha512/yescrypt (Debian: common-password)"
grep -Eq '^[[:space:]]*password[[:space:]]+.*pam_unix\.so\b.*\b(sha512|yescrypt)\b' /etc/pam.d/common-password 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[140] pwhistory remember ≥ 5 (Debian: common-password)"
grep -Eq '^[[:space:]]*password[[:space:]]+.*pam_pwhistory\.so\b.*\bremember=([5-9]|[1-9][0-9]+)\b' /etc/pam.d/common-password 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[141] deny ≥ 5 (faillock) (Debian: opção no PAM)"
grep -REq 'pam_faillock\.so\b.*\bdeny=([5-9]|[1-9][0-9]+)\b' /etc/pam.d/common-auth /etc/pam.d/common-account 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[142] unlock_time ≥ 900 (faillock) (Debian: opção no PAM)"
grep -REq 'pam_faillock\.so\b.*\bunlock_time=(9[0-9]{2}|[1-9][0-9]{3,})\b' /etc/pam.d/common-auth /etc/pam.d/common-account 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[143] PASS_MAX_DAYS ≤ 365"
val=$(awk '$1=="PASS_MAX_DAYS"{print $2; exit}' /etc/login.defs 2>/dev/null); [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -le 365 ]] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[144] PASS_MIN_DAYS ≥ 1"
grep -Eq '^[[:space:]]*PASS_MIN_DAYS[[:space:]]+[1-9][0-9]*\b' /etc/login.defs 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[145] PASS_WARN_AGE ≥ 7"
grep -Eq '^[[:space:]]*PASS_WARN_AGE[[:space:]]+([7-9]|[1-9][0-9]+)\b' /etc/login.defs 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[146] inactive ≥ 30 (Debian: campo 7 do /etc/shadow para contas com senha)"
awk -F: '$2~/^\$/{if($7=="" || $7<30) exit 1} END{exit 0}' /etc/shadow 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[147] campo 3 != 0"
awk -F: '$2~/^\$/{if($3==""||$3==0) exit 1} END{exit 0}' /etc/shadow 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
