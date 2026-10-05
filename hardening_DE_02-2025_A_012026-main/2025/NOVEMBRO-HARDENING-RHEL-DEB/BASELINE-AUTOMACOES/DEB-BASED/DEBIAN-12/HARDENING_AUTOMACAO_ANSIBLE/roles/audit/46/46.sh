#!/usr/bin/env bash
# [46] ASLR habilitado
echo -e "\n[46] Verifique se a randomização do espaço de endereços (ASLR) está habilitada"
if [ "$(sysctl -n kernel.randomize_va_space 2>/dev/null)" -eq 2 ]; then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# [47] ptrace_scope restrito
echo -e "\n[47] Verifique se o parâmetro ptrace_scope está restrito"
val=$(sysctl -n kernel.yama.ptrace_scope 2>/dev/null || echo 0)
if [[ "$val" =~ ^[1-3]$ ]]; then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

#Problema potencial: se não existir /etc/security/limits.d/*, o shell tenta abrir literalmente esse caminho → grep retorna 2 (erro). Isso faz o && encadear como se fosse falha → REPROVADO
#echo -e "\n[48] Verifique se core dumps estão desabilitados"
#egrep -q '^\s*\*\s+hard\s+core\s+0\b' /etc/security/limits.conf /etc/security/limits.d/* 2>/dev/null && sysctl -n fs.suid_dumpable 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[48] Verifique se core dumps estão desabilitados"
( cat /etc/security/limits.conf /etc/security/limits.d/*.conf 2>/dev/null \
    | egrep -q '^[[:space:]]*\*[[:space:]]+hard[[:space:]]+core[[:space:]]+0\b' \
  && sysctl -n fs.suid_dumpable 2>/dev/null | grep -q '^0$' ) \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
