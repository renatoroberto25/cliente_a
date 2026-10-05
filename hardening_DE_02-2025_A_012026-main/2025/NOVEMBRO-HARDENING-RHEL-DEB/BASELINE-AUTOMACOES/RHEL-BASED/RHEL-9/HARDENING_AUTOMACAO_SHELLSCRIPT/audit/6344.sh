#!/usr/bin/env bash

echo "269 Ensure audit log files group owner is configured"

# Captura o diretório dos logs do auditd.conf
audit_log_file=$(awk -F= '/^\s*log_file\s*/{print $2}' /etc/audit/auditd.conf | xargs)
audit_log_dir=$(dirname "$audit_log_file")

# Procura arquivos de log no diretório que não sejam do grupo root
arquivos_nao_root=$(find "$audit_log_dir" -maxdepth 1 -type f ! -group root)

if [ -n "$arquivos_nao_root" ]; then
echo "Os seguintes arquivos de log não pertencem ao grupo root:"
echo "$arquivos_nao_root"
echo "⚠️[REPROVADO] - Por favor revisar."
else
echo "✅ [APROVADO]:- Todos os arquivos de log em $audit_log_dir pertencem ao grupo root."
fi