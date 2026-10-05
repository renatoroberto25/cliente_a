#!/usr/bin/env bash

echo -e "\n[203] Recomendações de remediação – UID/GID 0 e senha root"

# --- 203 ---
echo "--- Corrigir usuários com UID 0 (exceto root) ---"
awk -F: '($3 == 0 && $1 != "root") {print "⚠️ Usuário com UID 0: "$1" — execute: usermod -u <NOVO_UID> "$1}' /etc/passwd

# --- 204 ---
echo "--- Corrigir usuários com GID 0 indevido ---"
awk -F: '($4 == 0 && $1 !~ /^(root|sync|shutdown|halt|operator)/) {print "⚠️ Usuário com GID 0: "$1" — execute: usermod -g <NOVO_GID> "$1}' /etc/passwd

# --- 205 ---
echo "--- Corrigir grupos com GID 0 (exceto root) ---"
awk -F: '($3 == 0 && $1 != "root") {print "⚠️ Grupo com GID 0: "$1" — execute: groupmod -g <NOVO_GID> "$1}' /etc/group

# --- 206 ---
echo "--- Garantir que o root tenha senha definida ---"
if ! passwd -S root | awk '{print $2}' | grep -q '^P'; then
  echo "⚠️ Conta root sem senha — execute: passwd root"
else
  echo "✅ Senha da conta root já definida"
fi

exit 0