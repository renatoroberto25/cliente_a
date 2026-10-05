#!/usr/bin/env bash

echo " [165] Verificar se o sudo está instalado"

if rpm -q sudo &>/dev/null; then
  if [ -x /usr/bin/sudo ]; then
    echo "✅ [APROVADO] sudo está instalado e executável disponível"
  else
    echo "⚠️ [REPROVADO] sudo instalado, mas executável não encontrado em /usr/bin/sudo"
  fi
else
  echo "⚠️ [REPROVADO] sudo não está instalado"
fi

echo -e "\n✅ Auditoria finalizada"
exit 0