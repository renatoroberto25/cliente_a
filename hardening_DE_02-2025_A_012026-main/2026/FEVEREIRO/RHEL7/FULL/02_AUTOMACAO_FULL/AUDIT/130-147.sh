#!/usr/bin/env bash

echo -e "\n[130] pwquality habilitado"
grep -Eq 'pam_pwquality\.so' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[132] pam_faillock habilitado"
grep -Eq 'pam_faillock\.so' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[133] pam_tally2 NÃO deve existir em RHEL 8/9"
! grep -Eq 'pam_tally2\.so' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[134] pam_pwhistory habilitado"
grep -Eq 'pam_pwhistory\.so' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[135] minlen ≥ 14"
grep -Psiq '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9]+)' /etc/security/pwquality.conf* \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[136] minclass ≥ 4"
grep -Psiq '^\s*minclass\s*=\s*[4-9]' /etc/security/pwquality.conf* \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[137] maxrepeat & maxsequence = 3"
grep -Psiq '^\s*maxrepeat\s*=\s*3\b'   /etc/security/pwquality.conf* &&
grep -Psiq '^\s*maxsequence\s*=\s*3\b' /etc/security/pwquality.conf* \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[138] dictcheck != 0"
! grep -Psiq '^\s*dictcheck\s*=\s*0\b' /etc/security/pwquality.conf* \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[139] Hashing sha512/yescrypt"
grep -Eq 'pam_unix\.so.*(sha512|yescrypt)' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


echo -e "\n[140] pwhistory remember ≥ 5"
grep -Eq 'pam_pwhistory\.so.*remember=[5-9]' /etc/pam.d/*auth \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[141] deny ≥ 5 (faillock)"
grep -Pi '^\s*deny\s*=\s*([5-9]|[1-9][0-9]+)' /etc/security/faillock.conf \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[142] unlock_time ≥ 900"
grep -Pi '^\s*unlock_time\s*=\s*(9[0-9]{2}|[1-9][0-9]{3,})\b' /etc/security/faillock.conf \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[143] PASS_MAX_DAYS ≤ 365"
val=$(awk '$1=="PASS_MAX_DAYS"{print $2; exit}' /etc/login.defs); [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -le 365 ]] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[144] PASS_MIN_DAYS ≥ 1"
grep -Eq '^\s*PASS_MIN_DAYS\s+[1-9][0-9]*' /etc/login.defs && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[145] PASS_WARN_AGE ≥ 7"
grep -Eq '^\s*PASS_WARN_AGE\s+([7-9]|[1-9][0-9]+)' /etc/login.defs && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[146] inactive ≥ 30 (para contas válidas)"
awk -F: '$2~/^\$/{print $1}' /etc/shadow \
  | xargs -r -I{} chage -l {} \
  | grep -Eq 'Inactive.*(3[0-9]|[4-9][0-9]+)' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[147] campo 3 != 0"
awk -F: '$2~/^\$/{if($3==""||$3==0) exit 1} END{exit 0}' /etc/shadow \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
