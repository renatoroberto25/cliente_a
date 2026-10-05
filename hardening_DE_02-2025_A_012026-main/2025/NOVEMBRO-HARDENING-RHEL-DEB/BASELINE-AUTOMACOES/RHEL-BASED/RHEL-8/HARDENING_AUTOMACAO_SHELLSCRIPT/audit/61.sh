#!/usr/bin/env bash
echo "[61 - 63] Verificar permissões e proprietário dos arquivos de banner"

for arquivo in /etc/motd /etc/issue /etc/issue.net; do
  if [ -e "$arquivo" ]; then
    perms=$(stat -c "%a" "$arquivo")
    owner=$(stat -c "%U:%G" "$arquivo")
    if [[ "$perms" == "644" && "$owner" == "root:root" ]]; then
      echo "✅ APROVADO - $arquivo: permissões $perms, proprietário $owner"
    else
      echo "⚠️ REPROVADO - $arquivo: permissões $perms, proprietário $owner"
    fi
  else
    echo "⚠️ REPROVADO - $arquivo não existe"
  fi
done