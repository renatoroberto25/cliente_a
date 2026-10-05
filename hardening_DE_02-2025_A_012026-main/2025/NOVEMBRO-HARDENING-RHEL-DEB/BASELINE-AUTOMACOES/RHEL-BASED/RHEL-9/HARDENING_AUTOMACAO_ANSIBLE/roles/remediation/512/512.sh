#!/usr/bin/env bash

echo " [144] Corrigir permissões dos arquivos de chave privada SSH"

data=$(date +%Y%m%d%H%M%S)
grupo_ssh=$(awk -F: '($1 ~ /^(ssh_keys|_?ssh)$/) { print $1 }' /etc/group)
[ -z "$grupo_ssh" ] && grupo_ssh="ssh_keys"

ajustar_chave_privada() {
  local arq="$1"
  local mode owner group
  read -r mode owner group < <(stat -Lc '%#a %U %G' "$arq")

  echo "→ Corrigindo $arq"
  cp -p "$arq" "$arq.bak.$data"

  if [ "$group" = "$grupo_ssh" ]; then
    chmod u-x,g-wx,o-rwx "$arq"
  else
    chmod u-x,go-rwx "$arq"
  fi

  chown root "$arq"
  [[ ! "$group" =~ ^(root|$grupo_ssh)$ ]] && chgrp "$grupo_ssh" "$arq"
}

while IFS= read -r -d '' arq; do
  if ssh-keygen -lf "$arq" &>/dev/null && file "$arq" | grep -Piq '\bopenssh.*private key\b'; then
    ajustar_chave_privada "$arq"
  fi
done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

echo -e "\n✅ Remediação finalizada"
exit 0