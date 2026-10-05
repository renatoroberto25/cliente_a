#!/usr/bin/env bash
echo "[99–100] Módulos de kernel DCCP e SCTP"

# 99 - Ensure DCCP is disabled
echo "[99] Verifique se o módulo DCCP está desabilitado"
if modprobe -n -v dccp 2>/dev/null | grep -q 'install /bin/true'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Adicione 'install dccp /bin/true' em /etc/modprobe.d/dccp.conf"
fi

# 100 - Ensure SCTP is disabled
echo "[100] Verifique se o módulo SCTP está desabilitado"
if modprobe -n -v sctp 2>/dev/null | grep -q 'install /bin/true'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Adicione 'install sctp /bin/true' em /etc/modprobe.d/sctp.conf"
fi