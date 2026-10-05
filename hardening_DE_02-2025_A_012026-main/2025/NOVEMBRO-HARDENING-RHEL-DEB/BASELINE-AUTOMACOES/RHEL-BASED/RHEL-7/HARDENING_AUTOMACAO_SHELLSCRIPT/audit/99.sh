#!/usr/bin/env bash
echo "[99–100] Verificações de módulos de kernel DCCP e SCTP"

# 99 - Ensure DCCP is disabled
echo "[99] Verifique se o módulo DCCP está desabilitado"
if modprobe -n -v dccp 2>/dev/null | grep -q 'install /bin/true'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

# 100 - Ensure SCTP is disabled
echo "[100] Verifique se o módulo SCTP está desabilitado"
if modprobe -n -v sctp 2>/dev/null | grep -q 'install /bin/true'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi