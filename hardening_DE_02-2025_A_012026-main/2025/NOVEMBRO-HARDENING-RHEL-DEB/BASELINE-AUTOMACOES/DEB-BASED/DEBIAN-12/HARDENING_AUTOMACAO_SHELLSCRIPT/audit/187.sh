#!/usr/bin/env bash
PAM_FILES="/etc/pam.d/common-auth /etc/pam.d/common-password /etc/pam.d/common-account /etc/pam.d/common-session"

echo -e "\n[187] Verifique se pam_unix está habilitado"
egrep -q "pam_unix.so" $PAM_FILES 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[188] Verifique se pam_faillock está habilitado"
egrep -q "pam_faillock.so" $PAM_FILES 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[189] Verifique se pam_pwquality está habilitado"
egrep -q "pam_pwquality.so" $PAM_FILES 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[190] Verifique se pam_pwhistory está habilitado"
egrep -q "pam_pwhistory.so" $PAM_FILES 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"