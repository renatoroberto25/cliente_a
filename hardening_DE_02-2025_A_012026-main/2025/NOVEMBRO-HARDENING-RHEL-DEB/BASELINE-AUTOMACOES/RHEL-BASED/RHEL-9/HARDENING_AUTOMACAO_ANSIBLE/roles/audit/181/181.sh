#!/usr/bin/env bash

echo -e "[68]	Certifique-se de que o GNOME Display Manager foi removido"

# Verifica se o pacote GDM está presente
if rpm -q gdm &>/dev/null; then
  echo -e "⚠️  [REPROVADO]: O GDM está instalado no sistema."
  echo -e "❗ Remova o pacote ou prossiga com a auditoria dos controles 68 a 76"
else
  echo -e "✅ [APROVADO]: GDM não está instalado."
  echo -e "⏭️  Controles 68 a 76 podem ser ignorados."
fi

exit 0