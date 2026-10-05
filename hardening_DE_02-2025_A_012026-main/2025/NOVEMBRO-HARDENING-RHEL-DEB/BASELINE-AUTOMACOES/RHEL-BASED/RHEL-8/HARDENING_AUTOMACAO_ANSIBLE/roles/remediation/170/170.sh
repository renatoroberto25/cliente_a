#!/usr/bin/env bash
set -o pipefail
echo "[170 - 190] Configurações de módulos PAM"

PAM_FILES="/etc/pam.d/system-auth /etc/pam.d/password-auth"

PWQ_DIR="/etc/security/pwquality.conf.d"
PWQ_MAIN="/etc/security/pwquality.conf"
PWQ_ALL="$PWQ_MAIN $(ls -1 ${PWQ_DIR}/*.conf 2>/dev/null)"

FAILLOCK_MAIN="/etc/security/faillock.conf"
FAILLOCK_DIR="/etc/security/faillock.conf.d"
FAILLOCK_ALL="$FAILLOCK_MAIN $(ls -1 ${FAILLOCK_DIR}/*.conf 2>/dev/null)"

PWHIST_CONF="/etc/security/pwhistory.conf"

ok() { echo "✅ Já conforme"; }
warn() { echo "⚠️ Não conforme — orientação:"; printf '%s\n' "$@"; }

# 170 — pam_faillock habilitado
echo -e "\n[170] Habilitar pam_faillock (auth/account)"
if egrep -i '^[[:space:]]*auth[[:space:]]+.*pam_faillock\.so' $PAM_FILES >/dev/null 2>&1 && \
   egrep -i '^[[:space:]]*account[[:space:]]+.*pam_faillock\.so' $PAM_FILES >/dev/null 2>&1; then
  ok
else
  warn \
" - Verifique o perfil ativo do authselect: head -1 /etc/authselect/authselect.conf" \
" - Se o template tiver marcadores {include if \"with-faillock\"}, habilite a feature e aplique:" \
"     authselect enable-feature with-faillock && authselect apply-changes" \
" - Se NÃO tiver os marcadores, inclua as linhas pam_faillock nos templates do perfil ativo e rode: authselect apply-changes"
fi

# 171 — pam_pwquality habilitado
echo -e "\n[171] Habilitar pam_pwquality"
if egrep -i 'pam_pwquality\.so' $PAM_FILES >/dev/null 2>&1; then
  ok
else
  warn \
" - Se o template tiver {include if \"with-pwquality\"} habilite:" \
"     authselect enable-feature with-pwquality && authselect apply-changes" \
" - Caso contrário, insira pam_pwquality.so nos templates do perfil e aplique mudanças" \
" - Parâmetros: prefira /etc/security/pwquality.conf(.d/*.conf) em vez de argumentos no módulo"
fi

# 172 — pam_pwhistory habilitado
echo -e "\n[172] Habilitar pam_pwhistory"
if egrep -i 'pam_pwhistory\.so' $PAM_FILES >/dev/null 2>&1; then
  ok
else
  warn \
" - Se o template tiver {include if \"with-pwhistory\"} habilite:" \
"     authselect enable-feature with-pwhistory && authselect apply-changes" \
" - Caso contrário, inclua pam_pwhistory.so (com use_authtok) nos templates e aplique mudanças"
fi

# 173 — pam_unix habilitado
echo -e "\n[173] Habilitar pam_unix"
if egrep -i 'pam_unix\.so' $PAM_FILES >/dev/null 2>&1; then
  ok
else
  warn \
" - Inclua pam_unix.so nos templates do perfil ativo (auth/account/password/session conforme stack) e rode authselect apply-changes"
fi

# 174 — deny 1–5 em faillock.conf (não no módulo)
echo -e "\n[174] Bloqueio por tentativas falhas (deny 1–5)"
if [ -n "$FAILLOCK_ALL" ] && egrep -i '^[[:space:]]*deny[[:space:]]*=[[:space:]]*[1-5]([[:space:]]|$)' $FAILLOCK_ALL >/dev/null 2>&1; then
  ok
else
  warn \
" - Configure em arquivo de conf (ex.: /etc/security/faillock.conf ou *.conf em faillock.conf.d):" \
"     deny = 5" \
" - Remova 'deny=' de linhas pam_faillock.so nos templates do authselect (use só o arquivo de conf)" \
" - Depois: authselect apply-changes"
fi

# 175 — unlock_time 0 ou ≥900
echo -e "\n[175] Tempo de desbloqueio (unlock_time = 0 ou ≥900)"
if [ -n "$FAILLOCK_ALL" ] && egrep -i '^[[:space:]]*unlock_time[[:space:]]*=[[:space:]]*(0|9[0-9]{2}|[1-9][0-9]{3,})([[:space:]]|$)' $FAILLOCK_ALL >/dev/null 2>&1; then
  ok
else
  warn \
" - Configure em conf (não no módulo):" \
"     unlock_time = 900" \
" - Remova 'unlock_time=' das linhas pam_faillock.so nos templates do authselect" \
" - Aplique: authselect apply-changes"
fi

# 176 — inclui root (even_deny_root ou root_unlock_time ≥60)
echo -e "\n[176] Lockout inclui root"
if [ -n "$FAILLOCK_ALL" ] && ( egrep -i '^[[:space:]]*even_deny_root([[:space:]]*=[[:space:]]*(1|yes|true))?([[:space:]]|$)' $FAILLOCK_ALL || \
                               egrep -i '^[[:space:]]*root_unlock_time[[:space:]]*=[[:space:]]*([6-9][0-9]|[1-9][0-9]{2,})([[:space:]]|$)' $FAILLOCK_ALL ); then
  ok
else
  warn \
" - Em conf: adicione 'even_deny_root' e/ou 'root_unlock_time = 60' (ou mais)" \
" - Remova 'even_deny_root' e 'root_unlock_time=' de pam_faillock.so nos templates do authselect" \
" - Aplique: authselect apply-changes"
fi

# 177 — difok ≥2
echo -e "\n[177] difok ≥2"
if [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*difok[[:space:]]*=[[:space:]]*[2-9][0-9]*([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1; then
  ok
else
  warn \
" - Configure em /etc/security/pwquality.conf(.d/*.conf):" \
"     difok = 2" \
" - Evite setar difok como argumento do módulo pam_pwquality.so"
fi

# 178 — minlen ≥14
echo -e "\n[178] minlen ≥14"
if [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*minlen[[:space:]]*=[[:space:]]*(1[4-9]|[2-9][0-9]{1,})([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1; then
  ok
else
  warn \
" - Configure em pwquality.conf(.d/*.conf):" \
"     minlen = 14" \
" - Evite 'minlen=' como argumento do módulo"
fi

# 179 — complexidade (minclass ≥4 OU créditos <0)
echo -e "\n[179] Complexidade (minclass ≥4 OU u/l/d/o credit negativos)"
if [ -n "$PWQ_ALL" ] && ( egrep -i '^[[:space:]]*minclass[[:space:]]*=[[:space:]]*([4-9]|[1-9][0-9]+)([[:space:]]|$)' $PWQ_ALL || \
                          ( egrep -i '^[[:space:]]*ucredit[[:space:]]*=[[:space:]]*-[1-9][0-9]*' $PWQ_ALL && \
                            egrep -i '^[[:space:]]*lcredit[[:space:]]*=[[:space:]]*-[1-9][0-9]*' $PWQ_ALL && \
                            egrep -i '^[[:space:]]*dcredit[[:space:]]*=[[:space:]]*-[1-9][0-9]*' $PWQ_ALL && \
                            egrep -i '^[[:space:]]*ocredit[[:space:]]*=[[:space:]]*-[1-9][0-9]*' $PWQ_ALL ) ); then
  ok
else
  warn \
" - Opção A (recomendada):" \
"     minclass = 4" \
" - Opção B (equivalente):" \
"     dcredit = -1; ucredit = -1; lcredit = -1; ocredit = -1" \
" - Configure em pwquality.conf(.d/*.conf), não no módulo"
fi

# 180 — maxrepeat ≤3 e ≠0
echo -e "\n[180] maxrepeat ≤3"
if [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*maxrepeat[[:space:]]*=[[:space:]]*[1-3]([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1; then
  ok
else
  warn " - Configure:  maxrepeat = 3  (em pwquality.conf(.d/*.conf); evite argumento no módulo)"
fi

# 181 — maxsequence ≤3 e ≠0
echo -e "\n[181] maxsequence ≤3"
if [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*maxsequence[[:space:]]*=[[:space:]]*[1-3]([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1; then
  ok
else
  warn " - Configure:  maxsequence = 3  (em pwquality.conf(.d/*.conf); evite argumento no módulo)"
fi

# 182 — dictcheck = 1 (não 0)
echo -e "\n[182] dictcheck habilitado (=1)"
if [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*dictcheck[[:space:]]*=[[:space:]]*1([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1; then
  ok
else
  warn \
" - Em pwquality.conf(.d/*.conf), garanta:" \
"     dictcheck = 1" \
" - Remova/evite 'dictcheck=0' e evite setar no módulo"
fi

# 183 — enforce_for_root (pwquality)
echo -e "\n[183] enforce_for_root (pwquality)"
if [ -n "$PWQ_ALL" ] && egrep -i '^[[:space:]]*enforce_for_root([[:space:]]*=[[:space:]]*(1|yes|true))?([[:space:]]|$)' $PWQ_ALL >/dev/null 2>&1; then
  ok
else
  warn \
" - Adicione em pwquality.conf(.d/*.conf):" \
"     enforce_for_root"
fi

# 184 — remember ≥24 (pwhistory)
echo -e "\n[184] pwhistory: remember ≥24"
if [ -f "$PWHIST_CONF" ] && egrep -i '^[[:space:]]*remember[[:space:]]*=[[:space:]]*(2[4-9]|[3-9][0-9]|[1-9][0-9]{2,})([[:space:]]|$)' "$PWHIST_CONF" >/dev/null 2>&1; then
  ok
else
  warn \
" - Em /etc/security/pwhistory.conf:" \
"     remember = 24" \
" - Remova 'remember=' do pam_pwhistory.so nos templates do authselect; depois 'authselect apply-changes'"
fi

# 185 — enforce_for_root (pwhistory)
echo -e "\n[185] pwhistory: enforce_for_root"
if [ -f "$PWHIST_CONF" ] && egrep -i '^[[:space:]]*enforce_for_root([[:space:]]*=[[:space:]]*(1|yes|true))?([[:space:]]|$)' "$PWHIST_CONF" >/dev/null 2>&1; then
  ok
else
  warn " - Em /etc/security/pwhistory.conf:  enforce_for_root"
fi

# 186 — pam_pwhistory com use_authtok
echo -e "\n[186] pam_pwhistory usa use_authtok"
if egrep -i '^[[:space:]]*password[[:space:]]+.*pam_pwhistory\.so.*use_authtok' $PAM_FILES >/dev/null 2>&1; then
  ok
else
  warn \
" - Adicione 'use_authtok' nas linhas pam_pwhistory.so nos templates do perfil ativo" \
" - Aplique: authselect apply-changes"
fi

# 187 — pam_unix sem nullok
echo -e "\n[187] pam_unix NÃO usa nullok"
if ! egrep -i '^[[:space:]]*(auth|account|password|session)[[:space:]]+(requisite|required|sufficient)[[:space:]]+pam_unix\.so.*nullok' $PAM_FILES >/dev/null 2>&1; then
  ok
else
  warn \
" - Habilite a feature sem nullok (se disponível):" \
"     authselect enable-feature without-nullok && authselect apply-changes" \
" - Ou remova 'nullok' dos templates pam_unix.so do perfil ativo e aplique mudanças"
fi

# 188 — pam_unix sem remember=
echo -e "\n[188] pam_unix NÃO usa remember=n"
if ! egrep -i '^[[:space:]]*password[[:space:]]+.*pam_unix\.so.*remember=[0-9]+' $PAM_FILES >/dev/null 2>&1; then
  ok
else
  warn \
" - Remova 'remember=' das linhas pam_unix.so nos templates do authselect" \
" - Aplique: authselect apply-changes"
fi

# 189 — pam_unix com hashing forte (sha512/yescrypt)
echo -e "\n[189] pam_unix usa hashing forte (sha512/yescrypt)"
if egrep -i '^[[:space:]]*password[[:space:]]+.*pam_unix\.so.*(sha512|yescrypt)' $PAM_FILES >/dev/null 2>&1; then
  ok
else
  warn \
" - Ajuste pam_unix.so nos templates do perfil ativo para incluir 'sha512' (ou 'yescrypt' se suportado)" \
" - Aplique: authselect apply-changes" \
" - Recomenda-se alinhar também /etc/login.defs e /etc/libuser.conf, e expirar senhas antigas"
fi

# 190 — pam_unix com use_authtok
echo -e "\n[190] pam_unix usa use_authtok"
if egrep -i '^[[:space:]]*password[[:space:]]+.*pam_unix\.so.*use_authtok' $PAM_FILES >/dev/null 2>&1; then
  ok
else
  warn \
" - Adicione 'use_authtok' às linhas pam_unix.so (password) nos templates do perfil ativo" \
" - Aplique: authselect apply-changes"
fi