#!/usr/bin/env bash
echo "[187 - 190] Remediação - Módulos PAM"

TS="$(date +%F_%H%M%S)"

AUTH="/etc/pam.d/common-auth"
PASS="/etc/pam.d/common-password"
ACC="/etc/pam.d/common-account"
SESS="/etc/pam.d/common-session"

# Backup dos arquivos relevantes
for f in $AUTH $PASS $ACC $SESS; do
  [ -f "$f" ] && cp "$f" "$f.bak_${TS}" && echo "❗ Backup criado: $f.bak_${TS}"
done

# 187 - pam_unix
echo -e "\n[187] Garantindo pam_unix habilitado"
if ! grep -q "pam_unix.so" $AUTH 2>/dev/null; then
  echo "auth    required    pam_unix.so" >> $AUTH
  echo "✅ pam_unix.so adicionado em $AUTH"
else
  echo "✅ pam_unix já presente"
fi

# 188 - pam_faillock
echo -e "\n[188] Garantindo pam_faillock habilitado"
if ! grep -q "pam_faillock.so" $AUTH 2>/dev/null; then
  echo "auth    required    pam_faillock.so" >> $AUTH
  echo "✅ pam_faillock.so adicionado em $AUTH"
else
  echo "✅ pam_faillock já presente"
fi

# 189 - pam_pwquality
echo -e "\n[189] Garantindo pam_pwquality habilitado"
if ! grep -q "pam_pwquality.so" $PASS 2>/dev/null; then
  echo "password    requisite    pam_pwquality.so" >> $PASS
  echo "✅ pam_pwquality.so adicionado em $PASS"
else
  echo "✅ pam_pwquality já presente"
fi

# 190 - pam_pwhistory
echo -e "\n[190] Garantindo pam_pwhistory habilitado"
if ! grep -q "pam_pwhistory.so" $PASS 2>/dev/null; then
  echo "password    required    pam_pwhistory.so" >> $PASS
  echo "✅ pam_pwhistory.so adicionado em $PASS"
else
  echo "✅ pam_pwhistory já presente"
fi