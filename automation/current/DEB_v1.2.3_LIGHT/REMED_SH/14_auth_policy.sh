#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

PWQ=/etc/security/pwquality.conf.d/99-hardening.conf
auth_policy() { local id="$1" name="$2"; echo "[$id] $name"; ensure_file "$PWQ"; case "$id" in 111) set_kv "$PWQ" maxrepeat 3; set_kv "$PWQ" maxsequence 3;; 112) set_kv "$PWQ" dictcheck 1;; *) echo "SKIP: alteração PAM exige validação de acesso de contingencia"; return;; esac; echo "OK: politica persistida"; }
login_def() { local id="$1" name="$2" key="$3" value="$4" file=/etc/login.defs; echo "[$id] $name"; backup_file "$file"; if grep -Eq "^[[:space:]]*$key[[:space:]]+" "$file"; then sed -i "s/^[[:space:]]*$key[[:space:]].*/$key $value/" "$file"; else printf '%s %s\n' "$key" "$value" >> "$file"; fi; echo "OK: $key=$value"; }
inactive_default() { echo "[$1] $2"; backup_file /etc/default/useradd; useradd -D -f 30 >/dev/null 2>&1 && echo 'OK: INACTIVE=30' || echo 'WARN: falha'; }

manual 105 'PAM complexidade' 'Ajustar a pilha PAM e testar login, SSH e sudo com uma sessão de contingência.'
auth_policy 111 'Sem repetição/sequência'
auth_policy 112 'Dicionário ativo'
auth_policy 113 'Hash forte'
login_def 116 PASS_MAX_DAYS PASS_MAX_DAYS 90
login_def 117 PASS_MIN_DAYS PASS_MIN_DAYS 1
login_def 118 PASS_WARN_AGE PASS_WARN_AGE 7
inactive_default 119 'INACTIVE configurado'
manual 120 'Datas de senha consistentes' 'Revisar e corrigir as datas de senha de cada conta com chage.'
