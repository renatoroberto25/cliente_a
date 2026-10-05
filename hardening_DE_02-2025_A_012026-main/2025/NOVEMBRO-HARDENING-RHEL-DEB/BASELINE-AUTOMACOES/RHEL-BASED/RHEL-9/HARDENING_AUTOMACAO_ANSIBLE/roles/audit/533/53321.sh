#!/usr/bin/env bash

echo -e "\n[183 - 189] Verificar parâmetros de qualidade de senha (pwquality.conf e *.conf)"

# --- 183 ---
echo "183 Ensure password number of changed characters is configured"
if grep -Psiq '^\h*difok\h*=\h*([2-9]|[1-9][0-9]+)\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf; then
  echo "  ✅ [APROVADO]: 'difok' configurado corretamente (>=2)"
else
  echo "  ⚠️ [REPROVADO]: 'difok' ausente ou menor que 2"
fi

# --- 184 ---
echo "184 Ensure password length is configured"
if grep -Psiq '^\h*minlen\h*=\h*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf; then
  echo "  ✅ [APROVADO]: 'minlen' configurado corretamente (>=14)"
else
  echo "  ⚠️ [REPROVADO]: 'minlen' ausente ou menor que 14"
fi

# --- 185 ---
echo "185 Ensure password complexity is configured"
if grep -Psiq '^\h*minclass\h*=\h*[4-9]\b|^\h*minclass\h*=\h*[1-9][0-9]+\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf; then
  echo "  ✅ [APROVADO]: 'minclass' configurado corretamente (>=4)"
else
  echo "  ⚠️ [REPROVADO]: 'minclass' ausente ou menor que 4"
fi

# --- 186 ---
echo "186 Ensure password same consecutive characters is configured"
if grep -Psiq '^\h*maxrepeat\h*=\h*[1-3]\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf; then
  echo "  ✅ [APROVADO]: 'maxrepeat' configurado corretamente (<=3)"
else
  echo "  ⚠️ [REPROVADO]: 'maxrepeat' ausente ou maior que 3"
fi

# --- 187 ---
echo "187 Ensure password maximum sequential characters is configured"
if grep -Psiq '^\h*maxsequence\h*=\h*[1-3]\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf; then
  echo "  ✅ [APROVADO]: 'maxsequence' configurado corretamente (<=3)"
else
  echo "  ⚠️ [REPROVADO]: 'maxsequence' ausente ou maior que 3"
fi

# --- 188 ---
echo "188 Ensure password dictionary check is enabled"
if grep -Psiq '^\h*dictcheck\h*=\h*0\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf; then
  echo "  ⚠️ [REPROVADO]: 'dictcheck = 0' encontrado (desativa verificação de dicionário)"
else
  echo "  ✅ [APROVADO]: 'dictcheck' não desativado (ausente ou diferente de 0)"
fi

# --- 189 ---
echo "189 Ensure password quality is enforced for the root user"
if grep -Psiq '^\h*enforce_for_root\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf; then
  echo "  ✅ [APROVADO]: 'enforce_for_root' presente"
else
  echo "  ⚠️ [REPROVADO]: 'enforce_for_root' ausente"
fi

echo -e "\n✅ Auditoria finalizada"