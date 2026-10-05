#!/usr/bin/env bash

# Ferramentas de audit
AUDIT_TOOLS="/sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules"

echo "274 Ensure audit tools owner is configured"
audit_tools_owner_nao_root=$(stat -Lc "%n %U" $AUDIT_TOOLS 2>/dev/null | awk '$2 != "root" {print}')
if [ -n "$audit_tools_owner_nao_root" ]; then
echo "Os seguintes executáveis não pertencem ao usuário root:"
echo "$audit_tools_owner_nao_root"
echo "⚠️[REPROVADO] - Por favor revisar."
else
echo "✅ [APROVADO]:- Todas as ferramentas de audit pertencem ao usuário root."
fi

echo "275 Ensure audit tools group owner is configured"
audit_tools_nao_root_group=$(stat -Lc "%n %G" /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules | awk '$2 != "root" {print}')

# Verifica se a variável arquivos_nao_root contém alguma coisa
if [ -n "$audit_tools_nao_root_group" ]; then
echo "Os seguintes executáveis não pertencem ao grupo root:"
echo "$audit_tools_nao_root_group"
echo "⚠️[REPROVADO] - Por favor revisar."
else
echo "✅ [APROVADO]:- Todos as ferrametnas de audit em /sbin pertencem ao grupo root."
fi