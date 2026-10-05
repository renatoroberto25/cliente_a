#!/usr/bin/env bash
echo "[196 - 200] Configurar contas de root e de sistema/ambiente"

# Arquivos de referência
PAM_FILES="/etc/pam.d/system-auth /etc/pam.d/password-auth"

echo -e "\n [196] GID primário do root é 0"
gid_root="$(awk -F: '$1=="root"{print $4}' /etc/passwd 2>/dev/null)"
[ "$gid_root" = "0" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [197] Umask do usuário root está configurada (027 ou 077)"
ROOT_FILES="/root/.bash_profile /root/.bashrc"
( egrep -i '^[[:space:]]*umask[[:space:]]+(027|077)\b' $ROOT_FILES >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [198] Contas de sistema estão seguras (shell nologin)"
UID_MIN="$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)"
UID_MIN="${UID_MIN:-1000}"
bad_sys_accts="$(awk -F: -v umin="$UID_MIN" '($1!~/^(root|halt|sync|shutdown|nfsnobody)$/ && ($3<umin || $3==65534) && $7!~/^(\/usr)?\/sbin\/nologin$/){print $1}' /etc/passwd 2>/dev/null)"
[ -z "$bad_sys_accts" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [199] Senha do root está definida"
root_field="$(awk -F: '$1=="root"{print $2}' /etc/shadow 2>/dev/null)"
echo "$root_field" | egrep -q '^\$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [200] /nologin NÃO está listado em /etc/shells"
( ! egrep -i '^[[:space:]]*[^#].*/nologin([[:space:]]|$)' /etc/shells >/dev/null 2>&1 ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"