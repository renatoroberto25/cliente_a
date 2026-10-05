#!/usr/bin/env bash

echo -e "\n[203] Verificações de privilégios UID/GID 0 e acesso root"

# --- 203 Ensure root is the only UID 0 account ---
echo "--- Verificando usuários com UID 0 ---"
uid_0_users=$(awk -F: '($3 == 0) { print $1 }' /etc/passwd | grep -v "^root$")

if [[ -z "$uid_0_users" ]]; then
  echo "✅ [APROVADO]: Apenas o root possui UID 0"
else
  echo "⚠️ [REPROVADO]: Usuário(s) com UID 0 encontrado(s): $uid_0_users"
fi

# --- 204 Ensure root is the only GID 0 account ---
echo "--- Verificando usuários com GID 0 ---"
gid_0_users=$(awk -F: '($1 !~ /^(root|sync|shutdown|halt|operator)/ && $4 == 0) {print $1}' /etc/passwd)

if [[ -z "$gid_0_users" ]]; then
  echo "✅ [APROVADO]: Apenas o root possui GID 0"
else
  echo "⚠️ [REPROVADO]: Usuário(s) com GID 0 encontrado(s): $gid_0_users"
fi

# --- 205 Ensure group root is the only GID 0 group ---
echo "--- Verificando grupos com GID 0 ---"
gid_0_groups=$(awk -F: '($3 == 0 && $1 != "root") {print $1}' /etc/group)

if [[ -z "$gid_0_groups" ]]; then
  echo "✅ [APROVADO]: Apenas o grupo root possui GID 0"
else
  echo "⚠️ [REPROVADO]: Grupo(s) com GID 0 encontrado(s): $gid_0_groups"
fi

# --- 206 Ensure root account access is controlled ---
echo "--- Verificando se o root possui senha definida ---"
if passwd -S root | awk '{print $2}' | grep -q '^P'; then
  echo "✅ [APROVADO]: Conta root possui senha"
else
  echo "⚠️ [REPROVADO]: Conta root sem senha definida"
fi

exit 0