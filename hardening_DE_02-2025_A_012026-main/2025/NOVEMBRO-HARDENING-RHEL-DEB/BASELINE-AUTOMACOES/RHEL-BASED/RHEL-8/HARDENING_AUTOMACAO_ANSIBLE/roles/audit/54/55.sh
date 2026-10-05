#!/usr/bin/env bash
echo "[55] Verificar se SHA1 está desabilitado na política de criptografia"

arquivo="/etc/crypto-policies/state/CURRENT.pol"

saida_hash=$(awk -F= '($1~/(hash|sign)/ && $2~/SHA1/ && $2!~/^\s*-\s*[^#\n\r]*SHA1/){print}' "$arquivo")
grep -Pq '^\h*sha1_in_certs\h*=\h*0\b' "$arquivo"
sha1_ok=$?

if [ -z "$saida_hash" ] && [ "$sha1_ok" -eq 0 ]; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi