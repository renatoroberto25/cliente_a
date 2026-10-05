#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

secure_shells() { echo "[$1] $2"; ensure_line /etc/shells /usr/sbin/nologin && echo 'OK: nologin registrado' || echo 'WARN: falha'; }
profile_value() { local id="$1" name="$2" key="$3" value="$4" file=/etc/profile.d/99-hardening.sh; echo "[$id] $name"; ensure_file "$file"; backup_file "$file"; if [[ "$key" == umask ]]; then grep -Eq '^umask ' "$file" && sed -i "s/^umask .*/umask $value/" "$file" || printf 'umask %s\n' "$value" >> "$file"; else if grep -Eq '^TMOUT=' "$file"; then sed -i "s/^TMOUT=.*/TMOUT=$value/" "$file"; else printf 'TMOUT=%s\n' "$value" >> "$file"; fi; ensure_line "$file" 'readonly TMOUT'; fi; chmod 0644 "$file"; echo "OK: $key=$value"; }
sudo_policy() { local id="$1" name="$2" file=/etc/sudoers.d/99-hardening line; echo "[$id] $name"; command -v visudo >/dev/null || { echo 'SKIP: sudo ausente'; return; }; case "$id" in 128) line='%sudo ALL=(ALL:ALL) ALL';; 129) line='Defaults use_pty';; 131) line='Defaults timestamp_timeout=5';; esac; ensure_file "$file" 0440; backup_file "$file"; ensure_line "$file" "$line"; chmod 0440 "$file"; visudo -cf "$file" >/dev/null 2>&1 && echo 'OK: sudoers valido' || { local b="${BACKED_UP[$file]:-}"; [[ -n "$b" ]] && cp -a "$b" "$file"; echo 'WARN: regra revertida'; }; }

manual 121 'Apenas root com UID 0' 'Revisar contas com UID 0, corrigir o UID e ajustar os arquivos associados.'
manual 122 'Apenas grupo root com GID 0' 'Revisar grupos com GID 0, corrigir o GID e ajustar os arquivos associados.'
manual 123 'Contas de sistema com shell inválido bloqueadas' 'Revisar as contas de serviço e trocar o shell das contas sem login autorizado.'
secure_shells 124 '/etc/shells validado'
manual 125 'PATH do root sem diretório inseguro' 'Remover do PATH do root entradas vazias, relativas ou graváveis por outros.'
profile_value 126 'Umask padrão restritiva' umask 027
profile_value 127 'Timeout de shell' TMOUT 900
sudo_policy 128 'Administração privilegiada via sudo restrita'
sudo_policy 129 'Sudo com pseudo-TTY'
sudo_policy 131 'Timeout de autenticação sudo'
