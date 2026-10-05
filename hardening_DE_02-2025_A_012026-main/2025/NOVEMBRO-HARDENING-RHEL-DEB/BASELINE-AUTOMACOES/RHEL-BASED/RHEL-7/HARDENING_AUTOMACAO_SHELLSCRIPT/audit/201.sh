#!/usr/bin/env bash
echo "[201–204] Auditoria de políticas de senha (pwquality, faillock, PAM)"

# 201 - Password creation requirements
echo "[201] Verifique requisitos de senha em /etc/security/pwquality.conf"
grep -Eq '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9]+)' /etc/security/pwquality.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 202 - Lockout for failed password attempts
echo "[202] Verifique política de bloqueio após falhas (deny <= 5)"
#grep -Eq '^\s*deny\s*=\s*[1-5]\b' /etc/security/faillock.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
[ -f /etc/security/faillock.conf ] && grep -Eq '^\s*deny\s*=\s*[1-5]\b' /etc/security/faillock.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 203 - Password hashing algorithm SHA-512
echo "[203] Verifique se SHA-512 está configurado nos módulos PAM"
grep -Eq '^\s*password\s+.*pam_unix\.so.*sha512' /etc/pam.d/system-auth /etc/pam.d/password-auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 204 - Password reuse limited
echo "[204] Verifique se política de histórico de senhas está configurada (remember >= 5)"
grep -Eq '^\s*password\s+.*pam_pwhistory\.so.*remember=[5-9]' /etc/pam.d/system-auth /etc/pam.d/password-auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "✅ Auditoria concluída"
exit 0