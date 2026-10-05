#!/usr/bin/env bash

echo -e "\n[190] Reforço de histórico de senhas – pwhistory.conf"

arquivo="/etc/security/pwhistory.conf"
bk="${arquivo}.bak.$(date +%Y%m%d%H%M%S)"
cp "$arquivo" "$bk" && echo "🗂️ Backup criado: $bk"

# 190 – remember >= 24
if grep -Pq '^\s*remember\s*=' "$arquivo"; then
  sed -i "s/^\s*remember\s*=.*/# &/" "$arquivo"
fi
echo -e "\n# Adicionado por script de remediação\nremember = 24" >> "$arquivo"
echo "✅ Parâmetro 'remember' ajustado para '24'"

# 191 – enforce_for_root
if grep -Pq '^\s*enforce_for_root\b' "$arquivo"; then
  echo "✅ Parâmetro 'enforce_for_root' já presente"
else
  echo -e "\n# Adicionado por script de remediação\nenforce_for_root" >> "$arquivo"
  echo "✅ Parâmetro 'enforce_for_root' adicionado"
fi