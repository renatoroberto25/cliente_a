#!/usr/bin/env bash

echo " [167] Verificar se o sudo está configurado com arquivo de log"

arquivo="/etc/sudoers"
esperado='Defaults logfile="/var/log/sudo.log"'

if grep -Fxq "$esperado" "$arquivo"; then
  echo "✅ [APROVADO] Linha exata encontrada: $esperado"
else
  echo "⚠️ [REPROVADO] Linha exata não encontrada em $arquivo"
  grep -i 'logfile' "$arquivo" || echo "ℹ️ Nenhuma linha contendo 'logfile' encontrada"
fi

echo -e "\n✅ Auditoria finalizada"
exit 0