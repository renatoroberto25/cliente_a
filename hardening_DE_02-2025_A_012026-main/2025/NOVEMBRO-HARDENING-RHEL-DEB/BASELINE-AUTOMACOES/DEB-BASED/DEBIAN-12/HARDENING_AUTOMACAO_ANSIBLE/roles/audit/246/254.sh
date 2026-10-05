#!/usr/bin/env bash
# [254–263] Auditoria - Regras de auditoria do auditd

echo -e "\n[254] Verifique se regras do auditd estão persistentes"
(ls /etc/audit/rules.d/*.rules >/dev/null 2>&1 || [ -s /etc/audit/audit.rules ]) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[255] Verifique se /etc/passwd está sendo auditado"
(auditctl -l 2>/dev/null | grep -q "/etc/passwd" || grep -q "/etc/passwd" /etc/audit/rules.d/*.rules 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[256] Verifique se /etc/shadow está sendo auditado"
(auditctl -l 2>/dev/null | grep -q "/etc/shadow" || grep -q "/etc/shadow" /etc/audit/rules.d/*.rules 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[257] Verifique se alteração de hora está sendo auditada"
(auditctl -l 2>/dev/null | grep -Eq "adjtimex|settimeofday|clock_settime" || grep -Eq "adjtimex|settimeofday|clock_settime" /etc/audit/rules.d/*.rules 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[258] Verifique se carregamento/remoção de módulos de kernel está sendo auditado"
(auditctl -l 2>/dev/null | grep -Eq "insmod|rmmod|modprobe" || grep -Eq "insmod|rmmod|modprobe" /etc/audit/rules.d/*.rules 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[259] Verifique se uso do sudo está sendo auditado"
(auditctl -l 2>/dev/null | grep -q "/etc/sudoers" || grep -q "/etc/sudoers" /etc/audit/rules.d/*.rules 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[260] Verifique se acesso ao su está sendo auditado"
(auditctl -l 2>/dev/null | grep -q "/bin/su" || grep -q "/bin/su" /etc/audit/rules.d/*.rules 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[261] Verifique se alterações de rede/hostname estão sendo auditadas"
(auditctl -l 2>/dev/null | grep -Eq "sethostname|setdomainname" || grep -Eq "/etc/(issue|hosts|network|netplan)" /etc/audit/rules.d/*.rules 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[262] Verifique se tentativas de acesso negado a arquivos estão sendo auditadas"
(auditctl -l 2>/dev/null | grep -Eq "EACCES|EPERM" || grep -Eq "EACCES|EPERM" /etc/audit/rules.d/*.rules 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[263] Verifique se mudanças de identidade de usuários/grupos estão sendo auditadas"
(auditctl -l 2>/dev/null | grep -Eq "/etc/(group|gshadow|shadow|security/opasswd|nsswitch.conf|pam)" || grep -Eq "/etc/(group|gshadow|shadow|security/opasswd|nsswitch.conf|pam)" /etc/audit/rules.d/*.rules 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"