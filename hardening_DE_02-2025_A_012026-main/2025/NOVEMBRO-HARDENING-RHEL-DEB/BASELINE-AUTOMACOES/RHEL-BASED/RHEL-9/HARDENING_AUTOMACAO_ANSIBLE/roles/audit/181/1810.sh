#!/bin/bash
echo -e "[77] Certifique-se de que o XDMCP não esteja habilitado"
# Verifica se o GDM está instalado
if ! command -v gdm >/dev/null 2>&1; then
   echo "✅ [APROVADO]: GDM não está instalado. Recomendação não se aplica."
   exit 0
fi

# Verifica se a configuração 'Enable=true' está presente
if grep -Eisq '^\s*Enable\s*=\s*true' /etc/gdm/custom.conf; then
   echo "⚠️ [REPROVADO]: A opção 'Enable=true' foi encontrada no arquivo /etc/gdm/custom.conf"
else
   echo "✅ [APROVADO]: A opção 'Enable=true' não foi encontrada no arquivo /etc/gdm/custom.conf"
fi

exit 0