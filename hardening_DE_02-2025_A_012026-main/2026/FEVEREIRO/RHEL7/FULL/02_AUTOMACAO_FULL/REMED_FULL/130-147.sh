#!/usr/bin/env bash
set -euo pipefail

backup_file() { [ -f "$1" ] && cp -a "$1" "$1.bak_$(date +%F-%H%M%S)"; }

# Arquivos PAM no RHEL7
PAM_SYSTEM="/etc/pam.d/system-auth"
PAM_PASSWD="/etc/pam.d/password-auth"

PWQ="/etc/security/pwquality.conf"
LOGIN="/etc/login.defs"

ensure_kv_conf() {
  # uso: ensure_kv_conf FILE KEY VALUE  (formato: key = value)
  local f="$1" k="$2" v="$3"
  backup_file "$f"
  if grep -Eq "^[[:space:]]*${k}[[:space:]]*=" "$f" 2>/dev/null; then
    sed -ri "s|^[[:space:]]*${k}[[:space:]]*=.*|${k} = ${v}|" "$f"
  else
    echo "${k} = ${v}" >> "$f"
  fi
}

ensure_kv_login_defs() {
  # uso: ensure_kv_login_defs KEY VALUE  (formato: KEY   VALUE)
  local k="$1" v="$2"
  backup_file "$LOGIN"
  if grep -Eq "^[[:space:]]*${k}[[:space:]]+" "$LOGIN" 2>/dev/null; then
    sed -ri "s|^[[:space:]]*${k}[[:space:]]+.*|${k}   ${v}|" "$LOGIN"
  else
    echo "${k}   ${v}" >> "$LOGIN"
  fi
}

ensure_line_after_regex() {
  # uso: ensure_line_after_regex FILE 'REGEX_ANCORA' 'LINHA_EXATA'
  local f="$1" anchor_re="$2" line="$3"
  grep -qxF "$line" "$f" 2>/dev/null && return 0
  backup_file "$f"
  awk -v are="$anchor_re" -v l="$line" '
    $0 ~ are { print; print l; next }
    { print }
  ' "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
}

ensure_line_before_regex() {
  # uso: ensure_line_before_regex FILE 'REGEX_ANCORA' 'LINHA_EXATA'
  local f="$1" anchor_re="$2" line="$3"
  grep -qxF "$line" "$f" 2>/dev/null && return 0
  backup_file "$f"
  awk -v are="$anchor_re" -v l="$line" '
    $0 ~ are { print l; print; next }
    { print }
  ' "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
}

########################################
# 130/131 – pam_pwquality habilitado
########################################
echo -e "\n[130/131] pam_pwquality habilitado"

# Garante pacote (RHEL7)
if ! rpm -q libpwquality &>/dev/null; then
  yum -y install libpwquality >/dev/null 2>&1 || true
fi

# Insere pam_pwquality.so antes do pam_unix.so (password stack) em ambos
for f in "$PAM_SYSTEM" "$PAM_PASSWD"; do
  [ -f "$f" ] || continue
  # Só adiciona se não existir
  if ! grep -Eq '^[[:space:]]*password[[:space:]]+requisite[[:space:]]+pam_pwquality\.so' "$f"; then
    ensure_line_before_regex "$f" '^[[:space:]]*password[[:space:]]+(sufficient|required)[[:space:]]+pam_unix\.so' \
      'password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3'
  fi
done
echo "✔ pam_pwquality presente no stack de password"

########################################
# 132/141/142 – pam_faillock (RHEL7: parâmetros no PAM)
########################################
echo -e "\n[132/141/142] pam_faillock habilitado (deny=5 unlock_time=900)"

# pacote
if ! rpm -q pam &>/dev/null; then
  yum -y install pam >/dev/null 2>&1 || true
fi

FA_PREAUTH='auth        required      pam_faillock.so preauth silent deny=5 unlock_time=900'
FA_AUTHFAIL='auth        [default=die] pam_faillock.so authfail deny=5 unlock_time=900'
FA_ACCOUNT='account     required      pam_faillock.so'

for f in "$PAM_SYSTEM" "$PAM_PASSWD"; do
  [ -f "$f" ] || continue

  # remove variantes antigas para ficar idempotente/limpo (sem duplicar)
  backup_file "$f"
  sed -ri '/pam_faillock\.so[[:space:]]+(preauth|authfail)/d' "$f"
  sed -ri '/^[[:space:]]*account[[:space:]]+required[[:space:]]+pam_faillock\.so/d' "$f"

  # insere preauth/authfail logo após pam_env (ou no topo do bloco auth)
  if grep -Eq '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_env\.so' "$f"; then
    ensure_line_after_regex "$f" '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_env\.so' "$FA_PREAUTH"
    ensure_line_after_regex "$f" '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_env\.so' "$FA_AUTHFAIL"
  else
    # fallback: coloca no início do arquivo
    ( printf '%s\n%s\n' "$FA_PREAUTH" "$FA_AUTHFAIL"; cat "$f" ) > "${f}.tmp" && mv "${f}.tmp" "$f"
  fi

  # garante account
  if grep -Eq '^[[:space:]]*account[[:space:]]+required[[:space:]]+pam_unix\.so' "$f"; then
    ensure_line_after_regex "$f" '^[[:space:]]*account[[:space:]]+required[[:space:]]+pam_unix\.so' "$FA_ACCOUNT"
  else
    echo "$FA_ACCOUNT" >> "$f"
  fi
done
echo "✔ pam_faillock aplicado no PAM (deny=5 unlock_time=900)"

########################################
# 133 – pam_tally2 (legacy)
########################################
echo -e "\n[133] pam_tally2 (LEGACY)"
echo "✔ Sem alteração automática (use apenas se teu ambiente exigir tally2)"

########################################
# 134/140 – pam_pwhistory remember=5
########################################
echo -e "\n[134/140] pam_pwhistory habilitado (remember=5)"

PH_LINE='password    required      pam_pwhistory.so remember=5 use_authtok'

for f in "$PAM_SYSTEM" "$PAM_PASSWD"; do
  [ -f "$f" ] || continue

  if grep -Eq 'pam_pwhistory\.so' "$f"; then
    backup_file "$f"
    # normaliza remember=5
    sed -ri 's/(pam_pwhistory\.so.*)remember=[0-9]+/\1remember=5/' "$f"
    grep -Eq 'pam_pwhistory\.so.*remember=' "$f" || sed -ri 's/(pam_pwhistory\.so.*)/\1 remember=5/' "$f"
  else
    # insere antes do pam_unix password
    ensure_line_before_regex "$f" '^[[:space:]]*password[[:space:]]+(sufficient|required)[[:space:]]+pam_unix\.so' "$PH_LINE"
  fi
done
echo "✔ pam_pwhistory presente e remember=5"

########################################
# 135–138 – pwquality.conf
########################################
echo -e "\n[135] minlen = 14"
ensure_kv_conf "$PWQ" "minlen" "14"

echo -e "\n[136] minclass = 4"
ensure_kv_conf "$PWQ" "minclass" "4"

echo -e "\n[137] maxrepeat=3 e maxsequence=3"
ensure_kv_conf "$PWQ" "maxrepeat" "3"
ensure_kv_conf "$PWQ" "maxsequence" "3"

echo -e "\n[138] dictcheck = 1"
ensure_kv_conf "$PWQ" "dictcheck" "1"
echo "✔ pwquality.conf ajustado"

########################################
# 139 – hashing forte (RHEL7: SHA512)
########################################
echo -e "\n[139] Hash forte (SHA512) no PAM + login.defs"

ensure_kv_login_defs "ENCRYPT_METHOD" "SHA512"

for f in "$PAM_SYSTEM" "$PAM_PASSWD"; do
  [ -f "$f" ] || continue
  backup_file "$f"
  # garante sha512 shadow nas linhas do pam_unix (password)
  if grep -Eq '^[[:space:]]*password[[:space:]]+.*pam_unix\.so' "$f"; then
    sed -ri 's|(^[[:space:]]*password[[:space:]]+.*pam_unix\.so)(.*)$|\1 sha512 shadow\2|' "$f"
    # remove duplicatas simples
    sed -ri 's/(sha512)([[:space:]]+sha512)+/\1/g; s/(shadow)([[:space:]]+shadow)+/\1/g' "$f"
  fi
done
echo "✔ SHA512 garantido"

########################################
# 143–145 – login.defs
########################################
echo -e "\n[143] PASS_MAX_DAYS = 365"
ensure_kv_login_defs "PASS_MAX_DAYS" "365"

echo -e "\n[144] PASS_MIN_DAYS = 1"
ensure_kv_login_defs "PASS_MIN_DAYS" "1"

echo -e "\n[145] PASS_WARN_AGE = 7"
ensure_kv_login_defs "PASS_WARN_AGE" "7"

########################################
# 146 – inactive = 30 (aplica em contas com hash)
########################################
echo -e "\n[146] inactive = 30 (chage --inactive)"
while read -r u; do
  chage --inactive 30 "$u" >/dev/null 2>&1 || true
done < <(awk -F: '$2 ~ /^\$/ {print $1}' /etc/shadow)
echo "✔ chage inactive aplicado"

########################################
# 147 – lastchg válido (não vazio / não 0)
########################################
echo -e "\n[147] lastchg válido (chage --lastday 1 quando vazio/0)"
while read -r u; do
  lastchg="$(awk -F: -v U="$u" '$1==U{print $3}' /etc/shadow)"
  if [ -z "${lastchg:-}" ] || [ "${lastchg:-0}" -eq 0 ] 2>/dev/null; then
    chage --lastday 1 "$u" >/dev/null 2>&1 || true
  fi
done < <(awk -F: '$2 ~ /^\$/ {print $1}' /etc/shadow)
echo "✔ lastchg ajustado quando necessário"

echo -e "\n✔ Remediação 130–147 (RHEL7) concluída"
