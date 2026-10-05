#!/usr/bin/env bash
echo "267 Ensure audit log files mode is configured"

# Verifica se o auditd.conf existe
if [[ -f /etc/audit/auditd.conf ]]; then
  LOG_DIR="$(dirname "$(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf | xargs)")"
  echo "Diretório dos logs de audit: $LOG_DIR"

  ACHOU_ALGUM=0

  # Procura arquivos com permissões mais permissivas que o recomendado
  while IFS= read -r FILE; do
    PERM_ATUAL=$(stat -c "%a" "$FILE")
    echo "⚠️ $FILE com permissões atuais: $PERM_ATUAL — ajustando..."
    chmod u-x,g-wx,o-rwx "$FILE" && \
    echo "✅ Permissões ajustadas para $FILE" || \
    echo "❌ Falha ao ajustar permissões para $FILE"
    ACHOU_ALGUM=1
  done < <(find "$LOG_DIR" -type f -perm /0137)

  [[ "$ACHOU_ALGUM" -eq 0 ]] && echo "✅ Todos os arquivos já estão com permissões corretas"
else
  echo "❌ Arquivo /etc/audit/auditd.conf não encontrado"
fi