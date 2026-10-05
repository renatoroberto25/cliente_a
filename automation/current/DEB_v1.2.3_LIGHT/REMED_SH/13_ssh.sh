#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

SSH_DROP=/etc/ssh/sshd_config.d/99-hardening.conf
ssh_commit() { if sshd -t 2>/dev/null; then systemctl reload ssh.service >/dev/null 2>&1 || systemctl reload sshd.service >/dev/null 2>&1 || true; return 0; fi; local b="${BACKED_UP[$SSH_DROP]:-}"; [[ -n "$b" ]] && cp -a "$b" "$SSH_DROP" || rm -f "$SSH_DROP"; return 1; }
ssh_permissions() { echo "[$1] $2"; backup_file /etc/ssh/sshd_config; backup_metadata /etc/ssh; chown root:root /etc/ssh/sshd_config; chmod 0600 /etc/ssh/sshd_config; chown root:root /etc/ssh; chmod 0755 /etc/ssh; echo "OK: permissoes SSH"; }
ssh_value() { local id="$1" name="$2" key="$3" value="$4"; echo "[$id] $name"; command -v sshd >/dev/null || { echo "SKIP: sshd ausente"; return; }; ensure_file "$SSH_DROP" 0600; if grep -Eiq "^[[:space:]]*$key[[:space:]]+$value([[:space:]]|$)" "$SSH_DROP"; then echo "OK: $key $value"; return; fi; backup_file "$SSH_DROP"; if grep -Eiq "^[[:space:]]*$key[[:space:]]+" "$SSH_DROP"; then sed -i "s|^[[:space:]]*$key[[:space:]].*|$key $value|I" "$SSH_DROP"; else printf '%s %s\n' "$key" "$value" >> "$SSH_DROP"; fi; ssh_commit && echo "OK: $key $value" || echo "WARN: configuracao rejeitada e revertida"; }

ssh_permissions 90 'Permissões do SSH'
ssh_value 91 'SyslogFacility do SSH seguro' SyslogFacility AUTHPRIV
ssh_value 93 'MaxAuthTries restritivo' MaxAuthTries 4
ssh_value 94 'IgnoreRhosts habilitado' IgnoreRhosts yes
ssh_value 95 'HostbasedAuthentication desabilitado' HostbasedAuthentication no
ssh_value 97 'PermitEmptyPasswords desabilitado' PermitEmptyPasswords no
ssh_value 98 'PermitUserEnvironment desabilitado' PermitUserEnvironment no
ssh_value 99 'UsePAM habilitado' UsePAM yes
ssh_value 100 'ClientAlive configurado' ClientAliveInterval 300
ssh_value 101 'LoginGraceTime restrito' LoginGraceTime 60
ssh_value 102 'MaxStartups restrito' MaxStartups 10:30:60
