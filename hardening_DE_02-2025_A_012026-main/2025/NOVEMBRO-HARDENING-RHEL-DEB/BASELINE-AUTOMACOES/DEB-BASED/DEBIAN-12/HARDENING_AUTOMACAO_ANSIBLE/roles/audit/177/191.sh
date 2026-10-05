#!/usr/bin/env bash
FAILLOCK="/etc/security/faillock.conf /etc/security/faillock.conf.d/*.conf"
PWQ="/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf"
PWHIST="/etc/security/pwhistory.conf"
PAM_PASS="/etc/pam.d/common-password"

# --- Faillock ---
echo -e "\n[191] Verifique se password failed attempts lockout está configurado (deny)"
egrep -q "deny\s*=" $FAILLOCK 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[192] Verifique se unlock_time está configurado"
egrep -q "unlock_time\s*=" $FAILLOCK 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[193] Verifique se even_deny_root ou root_unlock_time está configurado"
( egrep -q "even_deny_root" $FAILLOCK 2>/dev/null || egrep -q "root_unlock_time\s*=" $FAILLOCK 2>/dev/null ) \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# --- Pwquality ---
echo -e "\n[194] Verifique se difok está configurado"
egrep -q "difok\s*=" $PWQ 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[195] Verifique se minlen está configurado"
egrep -q "minlen\s*=" $PWQ 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[196] Verifique se password complexity está configurada"
grep -Psi '^\s*(minclass|dcredit|ucredit|lcredit|ocredit)\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null | grep -q . && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[197] Verifique se maxrepeat está configurado"
egrep -q "maxrepeat\s*=" $PWQ 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[198] Verifique se maxsequence está configurado"
egrep -q "maxsequence\s*=" $PWQ 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[199] Verifique se dictcheck está configurado"
egrep -q "dictcheck\s*=" $PWQ 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[200] Verifique se enforce_for_root está habilitado (pwquality)"
egrep -q "enforce_for_root" $PWQ 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[201] Verifique se enforce_for_root está habilitado explicitamente para root"
egrep -q "enforce_for_root" $PWQ 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# --- Pwhistory ---
echo -e "\n[202] Verifique se remember está configurado (pwhistory)"
egrep -q "remember\s*=" $PWHIST 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[203] Verifique se enforce_for_root está habilitado (pwhistory)"
egrep -q "enforce_for_root" $PWHIST 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[204] Verifique se use_authtok está habilitado (pwhistory)"
egrep -q "use_authtok" $PAM_PASS 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# --- Pam_unix ---
echo -e "\n[205] Verifique se pam_unix não usa nullok"
egrep -q "pam_unix.so.*nullok" $PAM_PASS 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[206] Verifique se pam_unix não usa remember=n"
egrep -q "pam_unix.so.*remember=" $PAM_PASS 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[207] Verifique se pam_unix usa hashing forte (sha512 ou yescrypt)"
egrep -q "pam_unix.so.*(sha512|yescrypt)" $PAM_PASS 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[208] Verifique se pam_unix inclui use_authtok"
egrep -q "pam_unix.so.*use_authtok" $PAM_PASS 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"