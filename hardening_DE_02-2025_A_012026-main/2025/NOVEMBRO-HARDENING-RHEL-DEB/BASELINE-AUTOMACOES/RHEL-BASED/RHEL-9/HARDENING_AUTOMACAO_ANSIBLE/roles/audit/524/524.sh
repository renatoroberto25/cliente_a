#!/usr/bin/env bash

echo " [168] Verificar se usuários prehitssam fornecer senha para escalonamento (sem NOPASSWD)"

if grep -Erq '^\s*[^#].*\bNOPASSWD\b' /etc/sudoers /etc/sudoers.d 2>/dev/null; then
  echo "⚠️ [REPROVADO] Encontradas entradas com NOPASSWD:"
  grep -Er '^\s*[^#].*\bNOPASSWD\b' /etc/sudoers /etc/sudoers.d 2>/dev/null
else
  echo "✅ [APROVADO] Nenhuma entrada com NOPASSWD encontrada"
fi

echo "⚠️ Remediação automatizada pode impactar execução remota via Ansible ou serviços"
echo "⚠️ Use a tag específica: remediation_hitss_168 para aplicar manualmente"

echo -e "\n✅ Auditoria finalizada"
exit 0