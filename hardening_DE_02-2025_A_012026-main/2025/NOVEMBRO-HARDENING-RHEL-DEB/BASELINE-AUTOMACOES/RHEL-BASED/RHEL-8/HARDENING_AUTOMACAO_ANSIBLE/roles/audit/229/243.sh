#!/usr/bin/env bash
set -u
echo -e "\n [243 - 249] Configurações de regras de audit"

echo "[243] Verifique se o uso do comando chcon é auditado"
(egrep -iq "chcon" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || \
 auditctl -l 2>/dev/null | egrep -iq "chcon") \
 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[244] Verifique se o uso do comando setfacl é auditado"
(egrep -iq "setfacl" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || \
 auditctl -l 2>/dev/null | egrep -iq "setfacl") \
 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[245] Verifique se o uso do comando chacl é auditado"
(egrep -iq "chacl" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || \
 auditctl -l 2>/dev/null | egrep -iq "chacl") \
 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[246] Verifique se o uso do comando usermod é auditado"
(egrep -iq "usermod" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || \
 auditctl -l 2>/dev/null | egrep -iq "usermod") \
 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[247] Verifique se o carregamento e descarregamento de módulos do kernel é auditado"
(egrep -iq "init_module|finit_module|delete_module|create_module|query_module|/usr/bin/kmod" \
 /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || \
 auditctl -l 2>/dev/null | egrep -iq "init_module|finit_module|delete_module|create_module|query_module|/usr/bin/kmod") \
 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[248] Verifique se a configuração do auditd é imutável (-e 2)"
egrep -q "^\s*-e\s+2\b" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null \
 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[249] Verifique se a configuração em disco e em execução estão sincronizadas (augenrules --check)"
augenrules --check 2>&1 | grep -q "No change" \
 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
