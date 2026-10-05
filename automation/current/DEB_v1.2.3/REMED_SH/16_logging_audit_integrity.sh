#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

enable_service() { echo "[$1] $2"; backup_unit "$3"; systemctl enable --now "$3" >/dev/null 2>&1 && echo "OK: $3" || echo "SKIP: $3 ausente ou indisponivel"; }
journald_policy() { echo "[$1] $2"; set_kv /etc/systemd/journald.conf Storage persistent; if [[ -e /var/log/journal ]]; then backup_metadata /var/log/journal; else backup_file /var/log/journal; fi; backup_unit systemd-journald.service; install -d -m 2755 /var/log/journal; systemctl restart systemd-journald >/dev/null 2>&1 && echo 'OK: journald persistente' || echo 'WARN: restart falhou'; }
logrotate_policy() { echo "[$1] $2"; ensure_file /etc/logrotate.conf; backup_file /etc/logrotate.conf; if grep -Eq '^[[:space:]]*rotate[[:space:]]+' /etc/logrotate.conf; then sed -i 's/^[[:space:]]*rotate[[:space:]].*/rotate 12/' /etc/logrotate.conf; else printf '\nrotate 12\n' >> /etc/logrotate.conf; fi; logrotate -d /etc/logrotate.conf >/dev/null 2>&1 && echo 'OK: logrotate valido' || echo 'WARN: validacao falhou'; }
audit_boot() { local id="$1" name="$2" file=/etc/default/grub.d/99-hardening-audit.cfg grub; echo "[$id] $name"; ensure_file "$file"; backup_file "$file"; for grub in /boot/grub/grub.cfg /boot/grub2/grub.cfg; do [[ -e "$grub" ]] && backup_file "$grub"; done; printf 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX audit=1"\n' > "$file"; command -v update-grub >/dev/null && update-grub >/dev/null 2>&1 && echo 'OK: audit=1 persistido; reboot necessario' || echo 'SKIP: update-grub ausente'; }
auditd_size() { echo "[$1] $2"; set_kv /etc/audit/auditd.conf max_log_file 32; set_kv /etc/audit/auditd.conf max_log_file_action ROTATE; echo 'OK: max_log_file=32 action=ROTATE'; }
audit_rules() { local id="$1" name="$2" file=/etc/audit/rules.d/50-hardening.rules; echo "[$id] $name"; [[ -d /etc/audit/rules.d ]] || { echo 'SKIP: auditd ausente'; return; }; ensure_file "$file" 0600; backup_file "$file"; case "$id" in 139) ensure_line "$file" '-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change'; ensure_line "$file" '-w /etc/localtime -p wa -k time-change';; 140) for p in passwd group shadow gshadow; do ensure_line "$file" "-w /etc/$p -p wa -k identity"; done;; 141) for p in hosts resolv.conf; do ensure_line "$file" "-w /etc/$p -p wa -k network"; done;; 142) ensure_line "$file" '-w /var/log/lastlog -p wa -k logins';; 143) ensure_line "$file" '-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat,chown,fchown,fchownat,lchown,setxattr -k perm_mod';; 144) ensure_line "$file" '-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EACCES -k access'; ensure_line "$file" '-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EPERM -k access';; 145) echo 'SKIP: lista SUID/SGID deve ser gerada e revisada no host'; return;; 146) ensure_line "$file" '-a always,exit -F arch=b64 -S mount,umount2 -k mounts';; 147) ensure_line "$file" '-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat,rmdir -k delete';; 148) ensure_line "$file" '-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k modules';; 149) ensure_line "$file" '-w /etc/sudoers -p wa -k scope'; ensure_line "$file" '-w /etc/sudoers.d -p wa -k scope';; 150) ensure_line "$file" '-e 2';; esac; if [[ "$id" == 150 ]]; then echo 'OK: imutabilidade persistida; reboot recomendado'; elif command -v augenrules >/dev/null && augenrules --load >/dev/null 2>&1; then echo 'OK: regras carregadas'; else echo 'WARN: regras persistidas; carga falhou'; fi; }
aide_timer() { echo "[$1] $2"; command -v aide >/dev/null || { echo 'SKIP: AIDE ausente; instalação requer repositório'; return; }; ensure_line /etc/cron.d/aide-hardening '0 5 * * * root /usr/bin/aide --check'; chmod 0644 /etc/cron.d/aide-hardening; echo 'OK: verificação diária configurada'; }

journald_policy 133 'Journald persistente'
enable_service 134 'Rsyslog habilitado' rsyslog.service
logrotate_policy 135 'Rotação de logs configurada'
enable_service 136 'auditd habilitado' auditd.service
audit_boot 137 'Auditoria habilitada desde o boot'
auditd_size 138 'max_log_file configurado'
audit_rules 139 'Auditoria de data e hora'
audit_rules 140 'Auditoria de contas e grupos'
audit_rules 141 'Auditoria de rede'
audit_rules 142 'Auditoria de login'
audit_rules 143 'Auditoria de permissões'
audit_rules 144 'Auditoria de EACCES e EPERM'
audit_rules 145 'Auditoria de executáveis privilegiados'
audit_rules 146 'Auditoria de mount'
audit_rules 147 'Auditoria de unlink e rename'
audit_rules 148 'Auditoria de módulos kernel'
audit_rules 149 'Auditoria de sudo e sudoers'
audit_rules 150 'Auditoria imutável'
aide_timer 151 'Verificação periódica de integridade'
