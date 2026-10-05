#!/usr/bin/env bash

echo " [170] Verificar se o tempo de timeout do sudo está configurado corretamente (timestamp_timeout ≤ 5)"

timeout=$(grep -Eo 'timestamp_timeout=[0-9]+' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | cut -d= -f2 | sort -nr | head -n1)

if [ -z "$timeout" ]; then
  echo "✅ [APROVADO] Nenhum timeout explícito encontrado, valor padrão do sistema será usado"
elif [ "$timeout" -le 5 ]; then
  echo "✅ [APROVADO] Timeout configurado dentro do limite permitido ($timeout minutos)"
else
  echo "⚠️ [REPROVADO] Timeout configurado como $timeout minutos (acima do limite de 5)"
fi

echo -e "\n✅ Auditoria finalizada"
exit 0