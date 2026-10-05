#!/usr/bin/env bash

echo -e "\n[197] Reforço das políticas globais de senha – /etc/login.defs e useradd -D"

arquivo="/etc/login.defs"
bk="${arquivo}.bak.$(date +%Y%m%d%H%M%S)"
cp "$arquivo" "$bk" && echo "🗂️  Backup criado: $bk"

# --- 197 Ensure password expiration is configured ---
echo "--- Aplicando PASS_MAX_DAYS = 365 ---"
if grep -qE "^\s*PASS_MAX_DAYS" "$arquivo"; then
  sed -i 's/^\s*PASS_MAX_DAYS\s\+[0-9]\+/PASS_MAX_DAYS 365/' "$arquivo"
else
  echo "PASS_MAX_DAYS 365" >> "$arquivo"
fi
echo "✅ PASS_MAX_DAYS configurado para 365"

# --- 198 Ensure minimum password days is configured ---
echo "--- Aplicando PASS_MIN_DAYS = 1 ---"
if grep -qE "^\s*PASS_MIN_DAYS" "$arquivo"; then
  sed -i 's/^\s*PASS_MIN_DAYS\s\+[0-9]\+/PASS_MIN_DAYS 1/' "$arquivo"
else
  echo "PASS_MIN_DAYS 1" >> "$arquivo"
fi
echo "✅ PASS_MIN_DAYS configurado para 1"

# --- 199 Ensure password expiration warning days is configured ---
echo "--- Aplicando PASS_WARN_AGE = 7 ---"
if grep -qE "^\s*PASS_WARN_AGE" "$arquivo"; then
  sed -i 's/^\s*PASS_WARN_AGE\s\+[0-9]\+/PASS_WARN_AGE 7/' "$arquivo"
else
  echo "PASS_WARN_AGE 7" >> "$arquivo"
fi
echo "✅ PASS_WARN_AGE configurado para 7"

# --- 200 Ensure strong password hashing algorithm is configured ---
echo "--- Aplicando ENCRYPT_METHOD = YESCRYPT ---"
if grep -qE "^\s*ENCRYPT_METHOD" "$arquivo"; then
  sed -i 's/^\s*ENCRYPT_METHOD\s\+\S\+/ENCRYPT_METHOD YESCRYPT/' "$arquivo"
else
  echo "ENCRYPT_METHOD YESCRYPT" >> "$arquivo"
fi
echo "✅ ENCRYPT_METHOD configurado para YESCRYPT"

# --- 201 Ensure inactive password lock is configured ---
echo "--- Aplicando useradd -D -f 45 e atualizando contas ---"
useradd -D -f 45
awk -F: '($2~/^\$.+\$/) { system("chage --inactive 45 " $1) }' /etc/shadow
echo "✅ Período de inatividade (INACTIVE) definido como 45 dias para contas válidas"

echo "✅ Remediação concluída"
exit 0