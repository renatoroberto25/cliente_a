#!/usr/bin/env bash
echo -e "\n[209] Verifique se PASS_MAX_DAYS está configurado (≤ 365)"
grep -Pi '^\s*PASS_MAX_DAYS\s+[0-9]+' /etc/login.defs | awk '{if ($2<=365 && $2>0) exit 0; else exit 1}' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[210] Verifique se PASS_MIN_DAYS está configurado (≥ 1)"
grep -Pi '^\h*PASS_MIN_DAYS\h+[0-9]+\b' /etc/login.defs | awk '{if ($2>=1) exit 0; else exit 1}' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[211] Verifique se PASS_WARN_AGE está configurado (≥ 7)"
grep -Pi '^\h*PASS_WARN_AGE\h+[0-9]+\b' /etc/login.defs | awk '{if ($2>=7) exit 0; else exit 1}' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[212] Verifique se algoritmo de hashing forte está configurado (sha512/yescrypt)"
grep -Pi '^\h*ENCRYPT_METHOD\h+(SHA512|YESCRYPT)\b' /etc/login.defs >/dev/null 2>&1 \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[213] Verifique se inatividade (INACTIVE) está configurada (≤ 45)"
useradd -D | grep -Pi '^INACTIVE=' | awk -F= '{if ($2>=0 && $2<=45) exit 0; else exit 1}' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[214] Verifique se todas as senhas foram alteradas no passado"
today_days="$(( $(date +%s) / 86400 ))"
awk -F: -v today="$today_days" '$2~/^\$/ && ($3=="" || $3==0 || $3>today){exit 1}' /etc/shadow \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"