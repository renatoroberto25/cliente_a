#!/usr/bin/env bash

echo -e "\n[193] Verificar se pam_unix não inclui 'nullok'"
if grep -Pq '^\h*(auth|account|password|session)\h+(requisite|required|sufficient)\h+pam_unix\.so\b.*\bnullok\b' /etc/pam.d/{password,system}-auth; then
  echo "⚠️ [REPROVADO]: nullok encontrado em pam_unix.so"
else
  echo "✅ [APROVADO]: nullok não encontrado em pam_unix.so"
fi

echo -e "\n[194] Verificar se pam_unix não inclui 'remember'"
if grep -Eq '^\s*password\s+.*pam_unix\.so.*\bremember=[0-9]+' /etc/pam.d/{password,system}-auth; then
  echo "⚠️ [REPROVADO]: remember=n encontrado em pam_unix.so"
else
  echo "✅ [APROVADO]: remember=n não encontrado em pam_unix.so"
fi

echo -e "\n[195] Verificar se pam_unix usa algoritmo forte (sha512 ou yescrypt)"
if grep -Pq '^\h*password\h+\S+\h+pam_unix\.so\h+.*\b(sha512|yescrypt)\b' /etc/pam.d/{password,system}-auth; then
  echo "✅ [APROVADO]: Algoritmo de hash forte (sha512 ou yescrypt) encontrado em pam_unix.so"
else
  echo "⚠️ [REPROVADO]: Algoritmo de hash forte não encontrado em pam_unix.so"
fi

echo -e "\n[196] Verificar se pam_unix inclui 'use_authtok'"
if grep -Pq '^\h*password\h+\S+\h+pam_unix\.so\h+.*\buse_authtok\b' /etc/pam.d/{password,system}-auth; then
  echo "✅ [APROVADO]: use_authtok encontrado em pam_unix.so"
else
  echo "⚠️ [REPROVADO]: use_authtok não encontrado em pam_unix.so"
fi