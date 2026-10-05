#!/usr/bin/env bash
set -o pipefail

echo "[191 - 195] Configurar parâmetros do conjunto de senhas(invasiva)"

TS="$(date +%Y%m%d%H%M%S)"
bk(){ [ -f "$1" ] && cp -a "$1" "${1}.bak_${TS}" && echo "✅ Backup: ${1}.bak_${TS}"; }

PAM_FILES=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
LOGIN_DEFS="/etc/login.defs"
LIBUSER="/etc/libuser.conf"
USERADD_DEF="/etc/default/useradd"

# Seleciona apenas usuários locais com hash de senha (campo 2 do shadow inicia com $)
users_with_pw() { awk -F: '$2 ~ /^\$/' /etc/shadow 2>/dev/null | cut -d: -f1; }

# 191 — hashing forte (sha512/yescrypt)
echo -e "\n[191] Configurar hashing forte (sha512/yescrypt)"
# a) pam_unix.so com sha512 se faltar (não mexe se já houver sha512/yescrypt)
for f in "${PAM_FILES[@]}"; do
  [ -f "$f" ] || continue
  if egrep -iq '^[[:space:]]*password[[:space:]]+.*pam_unix\.so' "$f" && \
     ! egrep -iq '^[[:space:]]*password[[:space:]]+.*pam_unix\.so.*(sha512|yescrypt)' "$f"; then
    bk "$f"
    sed -ri 's/^([[:space:]]*password[[:space:]]+.*pam_unix\.so\b.*)$/\1 sha512/' "$f"
    echo "✅ Acrescentado 'sha512' em $f"
  fi
done
# b) ENCRYPT_METHOD em /etc/login.defs (SHA512 para compatibilidade ampla)
if [ -f "$LOGIN_DEFS" ]; then
  if egrep -iq '^[[:space:]]*ENCRYPT_METHOD[[:space:]]+' "$LOGIN_DEFS"; then
    bk "$LOGIN_DEFS"
    sed -ri 's/^[[:space:]]*ENCRYPT_METHOD[[:space:]]+.*/ENCRYPT_METHOD SHA512/' "$LOGIN_DEFS"
  else
    bk "$LOGIN_DEFS"
    printf '\nENCRYPT_METHOD SHA512\n' >> "$LOGIN_DEFS"
  fi
  echo "✅ ENCRYPT_METHOD = SHA512 em $LOGIN_DEFS"
fi
# c) libuser.conf (se existir)
if [ -f "$LIBUSER" ]; then
  if egrep -iq '^[[:space:]]*(crypt_style|crypt_method)[[:space:]]*=' "$LIBUSER"; then
    bk "$LIBUSER"
    sed -ri 's/^[[:space:]]*(crypt_style|crypt_method)[[:space:]]*=.*/crypt_style = sha512/' "$LIBUSER"
  else
    bk "$LIBUSER"
    printf '\n# HITSS\ncrypt_style = sha512\n' >> "$LIBUSER"
  fi
  echo "✅ crypt_style = sha512 em $LIBUSER"
fi

# 192 — PASS_MAX_DAYS ≤ 365 (e aplicar em usuários)
echo -e "\n[192] Configurar expiração (PASS_MAX_DAYS ≤ 365)"
if [ -f "$LOGIN_DEFS" ]; then
  if egrep -iq '^[[:space:]]*PASS_MAX_DAYS[[:space:]]+' "$LOGIN_DEFS"; then
    bk "$LOGIN_DEFS"
    sed -ri 's/^[[:space:]]*PASS_MAX_DAYS[[:space:]]+.*/PASS_MAX_DAYS 365/' "$LOGIN_DEFS"
  else
    bk "$LOGIN_DEFS"
    printf '\nPASS_MAX_DAYS 365\n' >> "$LOGIN_DEFS"
  fi
  echo "✅ PASS_MAX_DAYS = 365 em $LOGIN_DEFS"
fi
# aplicar a usuários com valor >365, <=0 ou vazio
while IFS=: read -r u _ last min max warn inact rest; do
  [ -n "$u" ] || continue
  if [ -z "$max" ] || [ "${max:-0}" -le 0 ] 2>/dev/null || [ "${max:-0}" -gt 365 ] 2>/dev/null; then
    chage -M 365 "$u" >/dev/null 2>&1 && echo "✅ Ajustado MAX=365 -> $u"
  fi
done < <(egrep -v '^(root|sync|shutdown|halt):' /etc/shadow | awk -F: '$2 ~ /^\$/ {print $0}')

# 193 — PASS_WARN_AGE ≥ 7 (e aplicar em usuários)
echo -e "\n[193] Configurar aviso de expiração (PASS_WARN_AGE ≥ 7)"
if [ -f "$LOGIN_DEFS" ]; then
  if egrep -iq '^[[:space:]]*PASS_WARN_AGE[[:space:]]+' "$LOGIN_DEFS"; then
    bk "$LOGIN_DEFS"
    sed -ri 's/^[[:space:]]*PASS_WARN_AGE[[:space:]]+.*/PASS_WARN_AGE 7/' "$LOGIN_DEFS"
  else
    bk "$LOGIN_DEFS"
    printf '\nPASS_WARN_AGE 7\n' >> "$LOGIN_DEFS"
  fi
  echo "✅ PASS_WARN_AGE = 7 em $LOGIN_DEFS"
fi
# aplicar a usuários com WARN <7 ou vazio
while IFS=: read -r u _ last min max warn inact rest; do
  [ -n "$u" ] || continue
  if [ -z "$warn" ] || [ "${warn:-0}" -lt 7 ] 2>/dev/null; then
    chage -W 7 "$u" >/dev/null 2>&1 && echo "✅ Ajustado WARN=7 -> $u"
  fi
done < <(egrep -v '^(root|sync|shutdown|halt):' /etc/shadow | awk -F: '$2 ~ /^\$/ {print $0}')

# 194 — INACTIVE ≤ 30 (padrão e usuários)
echo -e "\n[194] Configurar bloqueio por inatividade (INACTIVE ≤ 30)"
# padrão do sistema
useradd -D -f 30 >/dev/null 2>&1 && echo "✅ useradd default INACTIVE=30"
# arquivo /etc/default/useradd (reforço)
if [ -f "$USERADD_DEF" ]; then
  if egrep -iq '^[[:space:]]*INACTIVE[[:space:]]*=' "$USERADD_DEF"; then
    bk "$USERADD_DEF"
    sed -ri 's/^[[:space:]]*INACTIVE[[:space:]]*=.*/INACTIVE=30/' "$USERADD_DEF"
  else
    bk "$USERADD_DEF"
    printf '\nINACTIVE=30\n' >> "$USERADD_DEF"
  fi
  echo "✅ INACTIVE=30 em $USERADD_DEF"
fi
# aplicar a usuários com INACTIVE >30, -1 (nunca) ou vazio
while IFS=: read -r u _ last min max warn inact rest; do
  [ -n "$u" ] || continue
  if [ -z "$inact" ] || [ "${inact:-0}" -lt 0 ] 2>/dev/null || [ "${inact:-0}" -gt 30 ] 2>/dev/null; then
    chage -I 30 "$u" >/dev/null 2>&1 && echo "✅ Ajustado INACTIVE=30 -> $u"
  fi
done < <(egrep -v '^(root|sync|shutdown|halt):' /etc/shadow | awk -F: '$2 ~ /^\$/ {print $0}')

# 195 — last password change deve estar no passado (corrige 0/futuro para hoje)
echo -e "\n[195] Corrigir última alteração de senha (no passado)"
today_days="$(( $(date +%s) / 86400 ))"
today_str="$(date +%Y-%m-%d)"
while IFS=: read -r u _ last _; do
  [ -n "$u" ] || continue
  # only users with hashed password
  if [ -z "$last" ] || [ "${last:-0}" -eq 0 ] 2>/dev/null || [ "${last:-0}" -gt "$today_days" ] 2>/dev/null; then
    chage -d "$today_str" "$u" >/dev/null 2>&1 && echo "✅ Ajustado lastchange=hoje -> $u"
  fi
done < <(awk -F: '$2 ~ /^\$/ {print $0}' /etc/shadow 2>/dev/null)