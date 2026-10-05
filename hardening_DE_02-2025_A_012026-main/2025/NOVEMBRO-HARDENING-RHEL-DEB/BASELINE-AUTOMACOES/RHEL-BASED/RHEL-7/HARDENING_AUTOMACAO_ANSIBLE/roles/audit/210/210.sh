#!/usr/bin/env bash
echo "[210–215] Verificações de segurança de contas e ambiente de login"

# [210] Ensure system accounts are secured
echo "[210] Verifique se contas de sistema estão seguras"
if awk -F: '($1!="root" && $3<1000 && $7!="/sbin/nologin" && $7!="/bin/false") {exit 1}' /etc/passwd; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

# [211] Ensure default group for root is GID 0
echo "[211] Verifique se o grupo padrão do root é GID 0"
if [ "$(grep "^root:" /etc/passwd | cut -d: -f4)" = "0" ]; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

# [212] Ensure default user shell timeout is configured
echo "[212] Verifique se TMOUT está configurado (<=900s, readonly e export)"
if grep -R "TMOUT" /etc/profile /etc/bashrc /etc/profile.d/*.sh 2>/dev/null | grep -vE '^#' | grep -Eq 'TMOUT=([1-8][0-9][0-9]|900)' && \
   grep -R "readonly TMOUT" /etc/profile /etc/bashrc /etc/profile.d/*.sh 2>/dev/null | grep -vq '^#' && \
   grep -R "export TMOUT" /etc/profile /etc/bashrc /etc/profile.d/*.sh 2>/dev/null | grep -vq '^#'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

# [213] Ensure default user umask is configured
echo "[213] Verifique se o umask padrão é 027 ou mais restritivo"
grep -R "umask 027" /etc/profile /etc/bashrc /etc/profile.d/*.sh &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


# [214] Ensure root login is restricted to system console
echo "[214] Verifique se o login do root está restrito a console segura"
if grep -vE '^(tty1|console|#)' /etc/securetty 2>/dev/null | grep -q .; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

# [215] Ensure access to the su command is restricted
echo "[215] Verifique se o uso do comando su é restrito via PAM"
if grep -Eq '^auth\s+(required|requisite)\s+pam_wheel\.so' /etc/pam.d/su; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

echo "[ℹ️ FIM]"
exit 0