#!/usr/bin/env bash
echo "[191 - 195] Configurar parâmetros do conjunto de senhas"

PAM_FILES="/etc/pam.d/system-auth /etc/pam.d/password-auth"

# 191 — Ensure strong password hashing algorithm is configured
echo -e "\n [191] Strong password hashing algorithm (sha512/yescrypt) configurado"
( egrep -i '^[[:space:]]*password[[:space:]]+.*pam_unix\.so.*\b(sha512|yescrypt)\b' $PAM_FILES >/dev/null 2>&1 || \
  egrep -i '^[[:space:]]*ENCRYPT_METHOD[[:space:]]+(SHA512|YESCRYPT)\b' /etc/login.defs >/dev/null 2>&1 || \
  egrep -i '^[[:space:]]*(crypt_style|crypt_method)[[:space:]]*=[[:space:]]*(sha512|yescrypt)\b' /etc/libuser.conf >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 192 — Ensure password expiration is 365 days or less
echo -e "\n [192] Password expiration (PASS_MAX_DAYS ≤ 365)"
LD="/etc/login.defs"
v_max="$(egrep -i '^[[:space:]]*PASS_MAX_DAYS[[:space:]]+[0-9]+' "$LD" 2>/dev/null | awk '{print $2}' | head -n1)"
if [ -n "$v_max" ] && [ "$v_max" -gt 0 ] 2>/dev/null && [ "$v_max" -le 365 ] 2>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

# 193 — Ensure password expiration warning days is 7 or more
echo -e "\n [193] Password expiration warning (PASS_WARN_AGE ≥ 7)"
v_warn="$(egrep -i '^[[:space:]]*PASS_WARN_AGE[[:space:]]+[0-9]+' "$LD" 2>/dev/null | awk '{print $2}' | head -n1)"
if [ -n "$v_warn" ] && [ "$v_warn" -ge 7 ] 2>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

# 194 — Ensure inactive password lock is 30 days or less
echo -e "\n [194] Inactive password lock (INACTIVE ≤ 30)"
# padrão do sistema (useradd -D) e arquivo /etc/default/useradd se existir
def_inact="$(useradd -D 2>/dev/null | awk -F= '/^INACTIVE=/{print $2}')"
[ -z "$def_inact" ] && def_inact="$(egrep -i '^[[:space:]]*INACTIVE[[:space:]]*=[[:space:]]*-?[0-9]+' /etc/default/useradd 2>/dev/null | awk -F= '{gsub(/[[:space:]]*/,"",$2); print $2}' | head -n1)"
if [ -n "$def_inact" ] && [ "$def_inact" -ge 0 ] 2>/dev/null && [ "$def_inact" -le 30 ] 2>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

# 195 — Ensure all users last password change date is in the past
echo -e "\n [195] Last password change (todos no passado)"
# compara campo 3 do /etc/shadow (dias desde 1970) com hoje
today_days="$(( $(date +%s) / 86400 ))"
bad="$(awk -F: -v today="$today_days" '
  $2 ~ /^\$/ {      # somente usuários com hash definido
    user=$1; last=$3;
    if (last=="" || last==0 || last>today) { print user }
  }
' /etc/shadow 2>/dev/null)"
if [ -z "$bad" ]; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
  echo "$bad" | sed 's/^/  - /'
fi

exit 0