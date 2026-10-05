#!/usr/bin/env bash
echo "268 Ensure audit log files owner is configured"

# Verifica se o arquivo de configuração do audit existe
if [[ -f /etc/audit/auditd.conf ]]; then
  LOG_DIR="$(dirname "$(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf | xargs)")"
  echo "Diretório dos logs de audit: $LOG_DIR"

  ACHOU_ALGUM=0

  # Procura arquivos que não são de propriedade do root
  while IFS= read -r FILE; do
    OWNER_ATUAL=$(stat -c "%U" "$FILE")
    echo "⚠️ $FILE é de propriedade de $OWNER_ATUAL — ajustando para root..."
    chown root "$FILE" && \
    echo "✅ Propriedade ajustada para root em $FILE" || \
    echo "❌ Falha ao ajustar propriedade em $FILE"
    ACHOU_ALGUM=1
  done < <(find "$LOG_DIR" -type f ! -user root)

  [[ "$ACHOU_ALGUM" -eq 0 ]] && echo "✅ Todos os arquivos já são de propriedade do root"
else
  echo "❌ Arquivo /etc/audit/auditd.conf não encontrado"
fi