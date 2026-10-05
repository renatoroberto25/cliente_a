#!/usr/bin/env bash

echo -e "\n[161] Stack de logs racionalizado"
( systemctl is-active rsyslog &>/dev/null || systemctl is-active systemd-journald &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[162] Journald configurado"
( grep -Eq '^\s*SystemMaxUse=' /etc/systemd/journald.conf 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[163] Rsyslog instalado e ativo"
( rpm -q rsyslog &>/dev/null && systemctl is-active rsyslog &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[164] Logrotate configurado para rsyslog"
( grep -Eq 'rsyslog' /etc/logrotate.d/* 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[165] auditd instalado e rodando"
( rpm -q audit &>/dev/null && systemctl is-active auditd &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[166] Auditoria ativa no boot (audit=1)"
( grep -Eq '\baudit=1\b' /proc/cmdline ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[167] Tamanho de armazenamento de audit log definido"
( grep -Eq '^\s*max_log_file\s*=\s*[1-9]' /etc/audit/auditd.conf ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[168] Logs de auditoria não excluídos automaticamente"
( grep -Eq '^\s*max_log_file_action\s*=\s*(keep_logs|rotate)' /etc/audit/auditd.conf ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[169] Auditoria de data/hora"
( auditctl -l 2>/dev/null | grep -Eq 'adjtimex|settimeofday|clock_settime' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[170] Auditoria de contas e grupos"
( auditctl -l 2>/dev/null | grep -Eq '/etc/(passwd|shadow|group|gshadow)' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[171] Auditoria de configuração de rede"
( auditctl -l 2>/dev/null | grep -Eq 'sethostname|setdomainname|/etc/hosts|/etc/sysconfig/network' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[172] Auditoria de eventos SELinux (MAC)"
( auditctl -l 2>/dev/null | grep -Eq 'MAC_POLICY_LOAD|selinux' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[173] Auditoria de login/logout"
( auditctl -l 2>/dev/null | grep -Eq '/var/(run/utmp|log/wtmp|log/lastlog)' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[174] Auditoria de permissões DAC"
( auditctl -l 2>/dev/null | grep -Eq 'chmod|chown|fchmod|fchown' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[175] Auditoria de acessos não autorizados"
( auditctl -l 2>/dev/null | grep -Eq 'EACCES|EPERM' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[176] Auditoria de comandos privilegiados"
( auditctl -l 2>/dev/null | grep -Eq '\-F auid>=1000.*\-S execve' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[177] Auditoria de mount/unmount"
( auditctl -l 2>/dev/null | grep -Eq 'mount|umount' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[178] Auditoria de deleção de arquivos"
( auditctl -l 2>/dev/null | grep -Eq 'unlink|rename|rmdir' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[179] Auditoria de kernel modules"
( auditctl -l 2>/dev/null | grep -Eq 'init_module|delete_module|finit_module' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[180] Auditoria de sudoers"
( auditctl -l 2>/dev/null | grep -Eq '/etc/sudoers|/etc/sudoers.d' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[181] Auditoria imutável configurada"
( auditctl -s 2>/dev/null | grep -Eq 'enabled\s+2' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"
