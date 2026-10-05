#!/usr/bin/env bash
#[275–284] Auditoria de permissões e propriedade do auditd e suas ferramentas

LOG_DIR="$(dirname $(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf 2>/dev/null | xargs))"
AUDIT_TOOLS="/sbin/auditctl /sbin/auditd /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/augenrules /usr/sbin/auditctl /usr/sbin/auditd"

echo -e "\n[275] – audit log files mode"
([ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ] && ! find "$LOG_DIR" -maxdepth 1 -type f -perm /137 | grep -q .) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[276] – audit log files owner"
([ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ] && ! find "$LOG_DIR" -maxdepth 1 -type f ! -user root | grep -q .) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[277] – audit log files group owner"
([ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ] && ! find "$LOG_DIR" -maxdepth 1 -type f ! -group root ! -group adm | grep -q .) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[278] – audit log directory mode"
([ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ] && [ $(stat -c "%a" "$LOG_DIR") -le 750 ]) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[279] – audit config files mode"
(! find /etc/audit -type f \( -name "*.conf" -o -name "*.rules" \) -perm /137 | grep -q .) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[280] – audit config files owner"
(! find /etc/audit -type f \( -name "*.conf" -o -name "*.rules" \) ! -user root | grep -q .) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[281] – audit config files group owner"
(! find /etc/audit -type f \( -name "*.conf" -o -name "*.rules" \) ! -group root | grep -q .) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[282] – audit tools mode"
(for tool in $AUDIT_TOOLS; do [ -e "$tool" ] && [ $(stat -c "%a" "$tool") -le 755 ] || exit 1; done) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[283] – audit tools owner"
(for tool in $AUDIT_TOOLS; do [ -e "$tool" ] && [ "$(stat -c "%U" "$tool")" = "root" ] || exit 1; done) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[284] – audit tools group owner"
(for tool in $AUDIT_TOOLS; do [ -e "$tool" ] && [ "$(stat -c "%G" "$tool")" = "root" ] || exit 1; done) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
