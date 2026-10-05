#!/usr/bin/env bash
# [35-38] Audit HITSS - Core dumps, NX, ASLR, Prelink (Servidores baseados em RHEL 7)
set -euo pipefail

echo -e "\n[35] Verifique se core dumps estão restritos"
if grep -Eq '^\*\s+hard\s+core\s+0' /etc/security/limits.conf /etc/security/limits.d/* 2>/dev/null \
  && sysctl -n fs.suid_dumpable 2>/dev/null | grep -qx 0; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

echo -e "\n[36] Verifique se o suporte NX/XD está ativo"
if dmesg | grep -qi 'NX (Execute Disable) protection: active'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

echo -e "\n[37] Verifique se a randomização de espaço de endereço (ASLR) está habilitada"
if [ "$(sysctl -n kernel.randomize_va_space 2>/dev/null)" = "2" ]; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

echo -e "\n[38] Verifique se o pacote prelink está ausente"
if ! rpm -q prelink &>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi