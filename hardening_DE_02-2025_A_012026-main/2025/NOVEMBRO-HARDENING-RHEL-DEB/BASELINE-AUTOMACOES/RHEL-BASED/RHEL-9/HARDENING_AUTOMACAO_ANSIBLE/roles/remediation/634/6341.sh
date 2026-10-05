#!/usr/bin/env bash
echo "266 Ensure the audit log file directory mode is configured"

# Obtém o diretório do arquivo de log do audit
AUDIT_LOG_DIR="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' /etc/audit/auditd.conf | xargs)")"
echo "Diretório do log do audit: $AUDIT_LOG_DIR"

# Obtém as permissões atuais em formato numérico (ex: 750)
PERM_ATUAL=$(stat -c "%a" "$AUDIT_LOG_DIR")

# Verifica se as permissões são mais restritivas que 750
# Requisitos: sem permissão de escrita para grupo e nenhuma permissão para outros (g-w,o-rwx)
if [[ $(stat -c "%A" "$AUDIT_LOG_DIR") =~ ^d[rwx-]{3}[^w][r-][x-]---$ ]]; then
  echo "✅ Permissões já estão corretas: $PERM_ATUAL"
else
  echo "⚠️ Permissões atuais: $PERM_ATUAL — ajustando para remover g+w e todas as permissões de outros..."
  chmod g-w,o-rwx "$AUDIT_LOG_DIR" && \
  echo "✅ Permissões ajustadas com sucesso" || \
  echo "❌ Falha ao ajustar permissões"
fi