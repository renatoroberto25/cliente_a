#!/usr/bin/env bash
echo "[61 - 66] Corrigir permissões dos arquivos de banner"

for arquivo in /etc/motd /etc/issue /etc/issue.net; do
  if [ -e "$arquivo" ]; then
    perms=$(stat -c "%a" "$arquivo")
    owner=$(stat -c "%U:%G" "$arquivo")
    if [[ "$perms" != "644" || "$owner" != "root:root" ]]; then
      echo "⚠️ Corrigindo $arquivo (perms: $perms, owner: $owner)"
      cp -p "$arquivo" "$arquivo.bak_$(date +%F_%H-%M-%S)"
      chown root:root "$arquivo"
      chmod 644 "$arquivo"
    else
      echo "✅ $arquivo já está em conformidade"
    fi
  else
    echo "ℹ️ $arquivo não existe"
  fi
done