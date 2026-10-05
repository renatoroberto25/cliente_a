


#!/usr/bin/env bash

echo "271 Ensure audit configuration files owner is configured"
arquivos_nao_root=$(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) ! -user root)

# Verifica se a variável arquivos_nao_root contém alguma coisa
if [ -n "$arquivos_nao_root" ]; then
echo "Os seguintes arquivos não pertencem ao user root:"
echo "$arquivos_nao_root"
echo "⚠️[REPROVADO] - Por favor revisar."
else
echo "✅ [APROVADO]:- Todos os arquivos .conf e .rules em /etc/audit/ pertencem ao user root."
fi