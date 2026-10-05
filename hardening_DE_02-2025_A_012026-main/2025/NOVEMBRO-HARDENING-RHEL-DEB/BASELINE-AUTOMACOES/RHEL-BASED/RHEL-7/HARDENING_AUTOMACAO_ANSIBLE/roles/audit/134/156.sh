#!/usr/bin/env bash
echo "[156–165] Verificações de logging e integridade"

echo "[156] Verifique se o rsyslog está instalado"
rpm -q rsyslog &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[157] Verifique se o rsyslog está habilitado e em execução"
systemctl is-enabled rsyslog &>/dev/null && systemctl is-active rsyslog &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[158] Verifique se as permissões padrão de arquivos de log estão configuradas"
grep -q "FileCreateMode 0640" /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[159] Verifique se o rsyslog está configurado adequadamente"
[ -s /etc/rsyslog.conf ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[160] Verifique se o rsyslog envia logs para host remoto"
grep -Eq '@@?[^ ]+' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[161] Verifique se o rsyslog aceita logs remotos apenas quando designado"
grep -q "imtcp" /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[162] Verifique se o journald encaminha logs para rsyslog"
grep -q "ForwardToSyslog=yes" /etc/systemd/journald.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[163] Verifique se o journald comprime logs grandes"
grep -q "Compress=yes" /etc/systemd/journald.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[164] Verifique se o journald grava logs em disco persistente"
grep -q "Storage=persistent" /etc/systemd/journald.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[165] Verifique se as permissões dos arquivos de log estão corretas"
find /var/log -type f ! -perm 0640 -exec echo "⚠️ REPROVADO - Corrigir permissões em {}" \; | grep . || echo "✅ APROVADO"

echo "[166] Verifique se o logrotate está configurado"
[ -s /etc/logrotate.conf ] && ls /etc/logrotate.d/* &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[000] Diretório do log de auditoria deve ser 0750 ou mais restritivo"
log_dir=$(dirname $(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf 2>/dev/null))
(test -d "$log_dir" && [ $(stat -c "%a" "$log_dir") -le 750 ]) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[000] Ferramentas de auditoria devem pertencer ao grupo root"
AUDIT_TOOLS="/sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules"
(stat -Lc "%G %n" $AUDIT_TOOLS 2>/dev/null | awk '{if ($1!="root") exit 1}') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[000] Ferramentas de auditoria devem ser 755 ou mais restritivas"
(stat -Lc "%a %n" $AUDIT_TOOLS 2>/dev/null | awk '{if ($1+0 > 755) exit 1}') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[000] Ferramentas de auditoria devem ser de propriedade do usuário root"
(stat -Lc "%U %n" $AUDIT_TOOLS 2>/dev/null | awk '{if ($1!="root") exit 1}') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"