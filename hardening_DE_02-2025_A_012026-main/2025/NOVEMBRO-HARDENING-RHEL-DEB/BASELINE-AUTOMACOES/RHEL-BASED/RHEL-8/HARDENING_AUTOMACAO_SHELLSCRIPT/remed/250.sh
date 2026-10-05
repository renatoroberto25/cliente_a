#!/usr/bin/env bash
echo "[250-259] Remediação de permissões e propriedade do auditd"

LOG_DIR="$(dirname $(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf 2>/dev/null))"
AUDIT_TOOLS="/sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules"

echo -e "\n[250] Diretório do log deve ser 0750 ou mais restritivo"
if [ -d "$LOG_DIR" ]; then
    chmod 750 "$LOG_DIR" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
else
    echo "⚠️ REPROVADO (diretório não encontrado)"
fi

echo -e "\n[251] Arquivos de log devem ser 0640 ou mais restritivos"
find "$LOG_DIR" -maxdepth 1 -type f 2>/dev/null | while read -r f; do
    chmod 640 "$f" || true
done
(! find "$LOG_DIR" -maxdepth 1 -type f -perm /137 | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[252] Apenas usuários autorizados devem possuir os arquivos de log"
find "$LOG_DIR" -maxdepth 1 -type f ! -user root -exec chown root {} +
(! find "$LOG_DIR" -maxdepth 1 -type f ! -user root | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[253] Apenas grupos autorizados devem possuir os arquivos de log"
find "$LOG_DIR" -maxdepth 1 -type f ! -group root -exec chgrp root {} +
(! find "$LOG_DIR" -maxdepth 1 -type f ! -group root | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[254] Arquivos de configuração do audit devem ser 640 ou mais restritivos"
find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) -exec chmod 640 {} +
(! find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) -perm /137 | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[255] Arquivos de configuração do audit devem ser de propriedade do root"
find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) ! -user root -exec chown root {} +
(! find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) ! -user root | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[256] Arquivos de configuração do audit devem pertencer ao grupo root"
find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) ! -group root -exec chgrp root {} +
(! find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) ! -group root | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"