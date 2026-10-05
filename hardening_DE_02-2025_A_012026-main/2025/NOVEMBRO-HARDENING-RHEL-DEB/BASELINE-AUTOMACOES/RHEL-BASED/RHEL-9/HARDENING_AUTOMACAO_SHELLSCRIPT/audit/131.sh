#!/usr/bin/env bash

echo " Auditoria: hitss 41 - 48 – Configuração do SELinux"

# 41 – Verificar se o SELinux está instalado
if rpm -q libselinux &>/dev/null; then
  echo "✅ [41] SELinux instalado"
else
  echo "⚠️ [41] SELinux NÃO está instalado"
fi

# 42 – Verificar se o bootloader não desabilita SELinux
if grubby --info=ALL | grep -Po '(selinux|enforcing)=0\b' &>/dev/null; then
  echo "⚠️ [42] SELinux DESABILITADO no bootloader"
else
  echo "✅ [42] SELinux habilitado no bootloader"
fi

# 43 – Verificar se a política do SELinux está definida
if grep -E '^\s*SELINUXTYPE=(targeted|mls)\b' /etc/selinux/config &>/dev/null; then
  echo "✅ [43] Política SELinux configurada"
else
  echo "⚠️ [43] Política SELinux NÃO configurada"
fi

# 44 – Verificar se o modo SELinux não está desabilitado
if grep -Ei '^\s*SELINUX=(enforcing|permissive)' /etc/selinux/config &>/dev/null; then
  echo "✅ [44] SELinux está ativo (enforcing ou permissive)"
else
  echo "⚠️ [44] SELinux DESATIVADO"
fi

# 45 – Verificar se o modo está em enforcing
if grep -qi '^SELINUX=enforcing' /etc/selinux/config; then
  echo "✅ [45] SELinux em modo enforcing"
else
  echo "⚠️ [45] SELinux NÃO está em modo enforcing"
fi

# 46 – Verificar se há serviços não confinados
if ps -eZ | grep -q unconfined_service_t; then
  echo "⚠️ [46] Serviços não confinados detectados:"
  ps -eZ | grep unconfined_service_t
else
  echo "✅ [46] Nenhum serviço não confinado encontrado"
fi

# 47 – Verificar se mcstrans está instalado
if rpm -q mcstrans &>/dev/null; then
  echo "⚠️ [47] Pacote 'mcstrans' instalado"
else
  echo "✅ [47] Pacote 'mcstrans' não está instalado"
fi

# 48 – Verificar se setroubleshoot está instalado
if rpm -q setroubleshoot &>/dev/null; then
  echo "⚠️ [48] Pacote 'setroubleshoot' instalado"
else
  echo "✅ [48] Pacote 'setroubleshoot' não está instalado"
fi

exit 0
