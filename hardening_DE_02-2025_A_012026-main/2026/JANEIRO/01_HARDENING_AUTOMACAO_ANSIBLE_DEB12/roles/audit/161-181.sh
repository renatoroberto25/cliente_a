#!/usr/bin/env bash

echo -e "\n[161] Stack de logs racionalizado"
( systemctl is-active rsyslog &>/dev/null || systemctl is-active systemd-journald &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[162] Journald configurado"
( systemd-analyze cat-config systemd/journald.conf* 2>/dev/null | grep -Eq 'SystemMaxUse=' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[163] Rsyslog instalado e ativo (Debian: dpkg)"
( dpkg -s rsyslog &>/dev/null && systemctl is-active rsyslog &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[164] Logrotate para rsyslog"
( grep -Eq 'rsyslog' /etc/logrotate.d/* 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[165] auditd instalado e rodando (Debian: dpkg)"
( dpkg -s auditd &>/dev/null && systemctl is-active auditd &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[166] Auditoria antes do auditd (kernel cmdline)"
( grep -Eq '\baudit=1\b' /proc/cmdline ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo -e "\n[167] Tamanho de armazenamento de audit log"
( grep -Eq '^\s*max_log_file\s*=\s*[1-9]' /etc/audit/auditd.conf ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[168] Logs de auditoria não excluídos automaticamente"
( grep -Eq '^\s*max_log_file_action\s*=\s*(keep_logs|rotate)' /etc/audit/auditd.conf ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[169] Auditoria de alterações em data/hora"
( auditctl -l 2>/dev/null | grep -Eq 'adjtimex|settimeofday|clock_settime' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[170] Auditoria de alterações em contas/grupos"
( auditctl -l 2>/dev/null | grep -Eq '/etc/(passwd|shadow|group|gshadow)' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[171] Auditoria de alterações no ambiente de rede"
( auditctl -l 2>/dev/null | grep -Eq 'sethostname|setdomainname|/etc/hosts|/etc/hostname' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[172] Auditoria de eventos MAC (Debian: AppArmor)"
( auditctl -l 2>/dev/null | grep -Eq 'apparmor|MAC_POLICY' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#ADAPTAR NO BASELINE

echo -e "\n[173] Auditoria de login/logout"
( auditctl -l 2>/dev/null | grep -Eq '/var/log/(faillog|lastlog)|/run/utmp' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[174] Auditoria de permissões DAC"
( auditctl -l 2>/dev/null | grep -Eq 'chmod|chown|fchmod|fchown' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[175] Auditoria de acessos não autorizados"
( auditctl -l 2>/dev/null | grep -Eq 'EACCES|EPERM' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[176] Auditoria de comandos privilegiados"
( auditctl -l 2>/dev/null | grep -Eq '^-w .* -p x' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#ADAPTAR NO BASELINE

echo -e "\n[177] Auditoria de mount/unmount"
( auditctl -l 2>/dev/null | grep -Eq 'mount|umount' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[178] Auditoria de deleção de arquivos"
( auditctl -l 2>/dev/null | grep -Eq 'unlink|rename|rmdir|unlinkat|renameat' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[179] Auditoria de kernel modules"
( auditctl -l 2>/dev/null | grep -Eq 'init_module|finit_module|delete_module' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[180] Auditoria de sudoers/logs de sudo"
( auditctl -l 2>/dev/null | grep -Eq '/etc/sudoers|/etc/sudoers.d' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[181] Configuração de auditoria imutável"
( auditctl -s 2>/dev/null | grep -Eq 'enabled.*2' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE
