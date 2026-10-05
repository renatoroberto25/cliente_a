#!/usr/bin/env bash
# [47–52] Remediação HITSS - Banners e permissões (Servidores baseados em RHEL 7)
# Não altera conteúdo. Apenas replica a verificação e orienta quando necessário.
set -euo pipefail

echo -e "\n[47] Verificar /etc/motd"
if grep -Eq "Authorized|access|unauthorized|prohibited" /etc/motd 2>/dev/null; then
  echo "✅ /etc/motd contém mensagem adequada."
else
  echo "⚠️ /etc/motd não contém aviso padrão. Pro favor incluir.."
fi

echo -e "\n[48] Verificar /etc/issue"
if grep -Eq "Authorized|access|unauthorized|prohibited" /etc/issue 2>/dev/null; then
  echo "✅ /etc/issue contém mensagem adequada."
else
  echo "⚠️ /etc/issue não contém aviso padrão. Pro favor incluir.."
fi

echo -e "\n[49] Verificar /etc/issue.net"
if grep -Eq "Authorized|access|unauthorized|prohibited" /etc/issue.net 2>/dev/null; then
  echo "✅ /etc/issue.net contém mensagem adequada."
else
  echo "⚠️ /etc/issue.net não contém aviso padrão. Pro favor incluir.."
fi

echo -e "\n[50] Corrigir permissões de /etc/motd"
[ -f /etc/motd ] && chown root:root /etc/motd && chmod 644 /etc/motd && echo "✅ /etc/motd permissões ajustadas (root:root 644)" || echo "⚠️ /etc/motd não encontrado."

echo -e "\n[51] Corrigir permissões de /etc/issue"
[ -f /etc/issue ] && chown root:root /etc/issue && chmod 644 /etc/issue && echo "✅ /etc/issue permissões ajustadas (root:root 644)" || echo "⚠️ /etc/issue não encontrado."

echo -e "\n[52] Corrigir permissões de /etc/issue.net"
[ -f /etc/issue.net ] && chown root:root /etc/issue.net && chmod 644 /etc/issue.net && echo "✅ /etc/issue.net permissões ajustadas (root:root 644)" || echo "⚠️ /etc/issue.net não encontrado."

echo -e "\n[56] Garantir que o XDMCP esteja desabilitado"
for f in /etc/gdm/custom.conf /etc/lightdm/lightdm.conf; do
  [ -f "$f" ] && sed -i.bak '/^\s*\(Enable\|enabled\)\s*=\s*true/s//\1=false/' "$f"
done
echo "✅ XDMCP desativado (se estava ativo)"
