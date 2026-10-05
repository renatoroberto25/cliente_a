#!/usr/bin/env bash

TS="$(date +%F_%H%M%S)"
FAILLOCK="/etc/security/faillock.conf"
PWQ="/etc/security/pwquality.conf"
PWHIST="/etc/security/pwhistory.conf"
PAM_PASS="/etc/pam.d/common-password"
CONF="/etc/security/pwquality.conf"
TS="$(date +%Y%m%d%H%M%S)"
# Backup
for f in $FAILLOCK $PWQ $PWHIST $PAM_PASS; do
  [ -f "$f" ] && cp "$f" "$f.bak_${TS}" && echo "❗ Backup criado: $f.bak_${TS}"
done
# --- 191–193 faillock ---
echo -e "\n[191–193] Ajustando faillock.conf"
grep -q "deny" $FAILLOCK 2>/dev/null || echo "deny = 5" >> $FAILLOCK
grep -q "unlock_time" $FAILLOCK 2>/dev/null || echo "unlock_time = 900" >> $FAILLOCK
grep -q "even_deny_root" $FAILLOCK 2>/dev/null || echo "even_deny_root" >> $FAILLOCK

# --- 194–201 pwquality ---
echo -e "\n[194–201] Ajustando pwquality.conf"
grep -q "difok" $PWQ 2>/dev/null || echo "difok = 2" >> $PWQ
grep -q "minlen" $PWQ 2>/dev/null || echo "minlen = 14" >> $PWQ
grep -q "maxrepeat" $PWQ 2>/dev/null || echo "maxrepeat = 3" >> $PWQ
grep -q "maxsequence" $PWQ 2>/dev/null || echo "maxsequence = 3" >> $PWQ
grep -q "dictcheck" $PWQ 2>/dev/null || echo "dictcheck = 1" >> $PWQ
grep -q "enforce_for_root" $PWQ 2>/dev/null || echo "enforce_for_root" >> $PWQ
echo -e "\n[196] Ajustando complexidade de senhas (pwquality.conf)"
# backup do arquivo original
[ -f "$CONF" ] && cp -p "$CONF" "${CONF}.bak_${TS}"
# só adiciona parâmetros se não existirem
grep -q '^[[:space:]]*minclass' "$CONF" 2>/dev/null || echo "minclass = 3" >> "$CONF"
grep -q '^[[:space:]]*ucredit' "$CONF" 2>/dev/null || echo "ucredit = -1" >> "$CONF"
grep -q '^[[:space:]]*lcredit' "$CONF" 2>/dev/null || echo "lcredit = -1" >> "$CONF"
grep -q '^[[:space:]]*dcredit' "$CONF" 2>/dev/null || echo "dcredit = -1" >> "$CONF"
grep -q '^[[:space:]]*ocredit' "$CONF" 2>/dev/null || echo "ocredit = -1" >> "$CONF"
#Fim do 196

echo "⚠️ Revisar política local: ajuste de complexidade aplicado apenas se ausente"

# --- 202–203 pwhistory ---
echo -e "\n[202–203] Ajustando pwhistory.conf"
grep -q "remember" $PWHIST 2>/dev/null || echo "remember = 24" >> $PWHIST
grep -q "enforce_for_root" $PWHIST 2>/dev/null || echo "enforce_for_root" >> $PWHIST

# --- 204–208 pam_unix ---
echo -e "\n[204–208] Ajustando common-password (pam_unix)"
# remove nullok
sed -i 's/\snullok//g' $PAM_PASS
# remove remember=
sed -i 's/\sremember=[0-9]\+//g' $PAM_PASS
# garante hashing forte
grep -q "pam_unix.so" $PAM_PASS && sed -i '/pam_unix.so/ s/$/ sha512/' $PAM_PASS
# garante use_authtok
grep -q "pam_unix.so" $PAM_PASS && sed -i '/pam_unix.so/ s/$/ use_authtok/' $PAM_PASS