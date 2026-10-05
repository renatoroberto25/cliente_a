#!/usr/bin/env bash
echo "[205–209] Políticas de expiração e bloqueio de senha"

# 205 - Ensure password expiration is 365 days or less
echo "[205] Verifique PASS_MAX_DAYS <= 365 em /etc/login.defs"
grep -Eq '^\s*PASS_MAX_DAYS\s+([1-9][0-9]{0,2})\b' /etc/login.defs && \
grep -E '^\s*PASS_MAX_DAYS\s+' /etc/login.defs | awk '{print $2}' | awk '$1 <= 365' | grep -q . && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 206 - Ensure minimum days between password changes is configured
echo "[206] Verifique PASS_MIN_DAYS >= 1 em /etc/login.defs"
grep -Eq '^\s*PASS_MIN_DAYS\s+[1-9][0-9]*' /etc/login.defs && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 207 - Ensure password expiration warning days is 7 or more
echo "[207] Verifique PASS_WARN_AGE >= 7 em /etc/login.defs"
grep -Eq '^\s*PASS_WARN_AGE\s+([7-9]|[1-9][0-9]+)\b' /etc/login.defs && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 208 - Ensure inactive password lock is 30 days or less
echo "[208] Verifique INACTIVE <= 30 via useradd -D"
useradd -D | grep -qE 'INACTIVE=[0-9]+' && \
useradd -D | awk -F= '/INACTIVE/{if($2<=30 && $2>=0)exit 0;else exit 1}' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 209 - Ensure all users last password change date is in the past
echo "[209] Verifique se todos os usuários possuem data de última alteração de senha válida"
awk -F: '$2~/^\$.+\$/{print $1}' /etc/shadow | while read -r user; do
  data=$(chage -l "$user" | grep '^Last password change' | cut -d: -f2- | xargs)
  if [[ -z "$data" || "$data" == "never" ]]; then
    echo "⚠️ REPROVADO: $user nunca alterou a senha"
  elif date -d "$data" >/dev/null 2>&1; then
    [[ $(date -d "$data" +%s) -le $(date +%s) ]] && echo "✅ $user OK ($data)" || echo "⚠️ REPROVADO: $user data futura ($data)"
  else
    echo "❗ Erro ao interpretar data de $user"
  fi
done
exit 0