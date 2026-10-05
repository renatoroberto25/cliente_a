#!/usr/bin/env bash
echo "[141–155] Verificações de regras e eventos auditáveis"

echo "[141] Verifique se eventos de data e hora são coletados"
grep -q "time-change" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[142] Verifique se eventos de usuários e grupos são coletados"
grep -q "identity" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[143] Verifique se eventos de rede são coletados"
grep -q "system-locale" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[144] Verifique se eventos de MAC são coletados"
grep -q "MAC-policy" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[145] Verifique se logins e logouts são coletados"
grep -q "logins" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[146] Verifique se informações de sessão são coletadas"
grep -q "session" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[147] Verifique se modificações de permissões são coletadas"
grep -q "perm_mod" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[148] Verifique se tentativas de acesso não autorizado são coletadas"
grep -q "access" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[149] Verifique se uso de comandos privilegiados é coletado"
grep -Eq '^-a always,exit .* -k privileged' /etc/audit/rules.d/*.rules 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[150] Verifique se montagens de sistemas de arquivos são coletadas"
grep -q "mounts" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[151] Verifique se deleções de arquivos são coletadas"
grep -q "delete" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[152] Verifique se alterações no sudoers são coletadas"
grep -q "sudoers" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[153] Verifique se execuções de comandos via sudo são coletadas"
grep -q "sudo_log" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[154] Verifique se carregamento e descarregamento de módulos são coletados"
grep -q "modules" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[155] Verifique se a configuração do auditd é imutável"
grep -q "^-e 2" /etc/audit/rules.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "[000] Verifique se o uso do comando chcon é auditado"
(egrep -iq "chcon" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || auditctl -l 2>/dev/null | egrep -iq "chcon") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "[000] Verifique se o uso do comando setfacl é auditado"
(egrep -iq "setfacl" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || auditctl -l 2>/dev/null | egrep -iq "setfacl") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "[000] Verifique se o uso do comando chacl é auditado"
(egrep -iq "chacl" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || auditctl -l 2>/dev/null | egrep -iq "chacl") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[000] Verifique se o uso do comando usermod é auditado"
(egrep -iq "usermod" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || auditctl -l 2>/dev/null | egrep -iq "usermod") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"