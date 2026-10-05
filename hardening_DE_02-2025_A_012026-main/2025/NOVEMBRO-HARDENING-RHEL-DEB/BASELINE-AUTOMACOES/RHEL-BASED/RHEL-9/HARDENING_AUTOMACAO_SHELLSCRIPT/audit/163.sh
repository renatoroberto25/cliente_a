#!/usr/bin/env bash

echo -e "\n 57 – Verificar se suporte a SHA1 (hash e assinatura) está desativado"

arquivo="/etc/crypto-policies/state/CURRENT.pol"

# Verificar se há uso indevido de SHA1 em hash/sign
saida_hash=$(awk -F= '($1~/(hash|sign)/ && $2~/SHA1/ && $2!~/^\s*-\s*[^#\n\r]*SHA1/){print}' "$arquivo")

# Verificar se sha1_in_certs está definido como 0
grep -Pq '^\h*sha1_in_certs\h*=\h*0\b' "$arquivo"
sha1_ok=$?

if [ -z "$saida_hash" ] && [ "$sha1_ok" -eq 0 ]; then
   echo -e "\n✅ [APROVADO]: Suporte a SHA1 está desativado."
else
   echo -e "\n⚠️  [REPROVADO]: SHA1 ainda está habilitado em alguma configuração."
fi

echo -e "\n📄 Trechos relevantes de $arquivo:"
[ -n "$saida_hash" ] && echo "$saida_hash"
grep -Pi '^\h*sha1_in_certs\h*=' "$arquivo"
