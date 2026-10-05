#!/usr/bin/env bash
echo "[250-256] Permissões e propriedade de logs e configs do auditd"

echo -e "\n[250] Diretório do log de auditoria deve ser 0750 ou mais restritivo"
(test -d "$(dirname $(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf 2>/dev/null))" && [ $(stat -c "%a" "$(dirname $(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf 2>/dev/null))") -le 750 ]) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[251] Arquivos de log de auditoria devem ser 0640 ou mais restritivos"
(LOG_DIR="$(dirname $(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf 2>/dev/null))"; [ -n "$LOG_DIR" ] && ! find "$LOG_DIR" -maxdepth 1 -type f -perm /137 | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[252] Apenas usuários autorizados devem possuir os arquivos de log"
(LOG_DIR="$(dirname $(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf 2>/dev/null))"; [ -n "$LOG_DIR" ] && ! find "$LOG_DIR" -maxdepth 1 -type f ! -user root | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[253] Apenas grupos autorizados devem possuir os arquivos de log"
(LOG_DIR="$(dirname $(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf 2>/dev/null))"; [ -n "$LOG_DIR" ] && ! find "$LOG_DIR" -maxdepth 1 -type f ! -group root | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[254] Arquivos de configuração do audit devem ser 640 ou mais restritivos"
(! find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) -perm /137 | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[255] Arquivos de configuração do audit devem ser de propriedade do root"
(! find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) ! -user root | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[256] Arquivos de configuração do audit devem pertencer ao grupo root"
(! find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) ! -group root | grep . >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"