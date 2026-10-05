#!/usr/bin/env bash

echo -e "\n[182] Bloqueio de senha para conta root – pam_faillock"

arquivo="/etc/security/faillock.conf"
bk="${arquivo}.bak.$(date +%Y%m%d%H%M%S)"
cp "$arquivo" "$bk" && echo "🗂️ Backup criado: $bk"

# even_deny_root
if grep -Pq '^\s*even_deny_root\b' "$arquivo"; then
  echo "✅ 'even_deny_root' já configurado corretamente."
else
  echo "⚠️ 'even_deny_root' não encontrado ou comentado. Adicionando..."
  echo -e "\n# Adicionado por script de remediação\neven_deny_root" >> "$arquivo"
  echo "✅ 'even_deny_root' adicionado ao final do arquivo."
fi

# root_unlock_time
valor_atual=$(grep -Pi '^\s*root_unlock_time\s*=' "$arquivo" | awk -F= '{gsub(/ /,"",$2); print $2}' | head -n1)

if [[ -n "$valor_atual" ]]; then
  if [[ "$valor_atual" -lt 60 ]]; then
    sed -i 's/^\s*root_unlock_time\s*=.*/root_unlock_time = 60/' "$arquivo"
    echo "⚠️ 'root_unlock_time' ajustado de $valor_atual para 60."
  else
    echo "✅ 'root_unlock_time' já está configurado corretamente (>= 60)."
  fi
else
  echo -e "\n# Adicionado por script de remediação\nroot_unlock_time = 60" >> "$arquivo"
  echo "✅ 'root_unlock_time = 60' adicionado ao final do arquivo."
fi