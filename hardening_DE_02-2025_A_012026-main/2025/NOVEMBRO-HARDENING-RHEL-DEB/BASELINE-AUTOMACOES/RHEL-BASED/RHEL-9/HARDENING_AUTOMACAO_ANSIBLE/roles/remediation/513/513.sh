#!/usr/bin/env bash

echo " [145] Corrigir permissões dos arquivos de chave pública SSH"

data=$(date +%Y%m%d%H%M%S)
pmask='0133'
maxperm=$(printf '%o' $((0777 & ~$pmask)))

ajustar_chave_publica() {
  local arq="$1"
  local mode owner group
  read -r mode owner group < <(stat -Lc '%#a %U %G' "$arq")

  echo "→ Corrigindo $arq"
  cp -p "$arq" "$arq.bak.$data"
  chmod 644 "$arq"
  chown root:root "$arq"
}

while IFS= read -r -d '' arq; do
  if ssh-keygen -lf "$arq" &>/dev/null && file "$arq" | grep -Piq '\bopenssh.*public key\b'; then
    read -r mode owner group < <(stat -Lc '%#a %U %G' "$arq")

    if [ $((mode & pmask)) -gt 0 ] || [ "$owner" != "root" ] || [ "$group" != "root" ]; then
      ajustar_chave_publica "$arq"
    fi
  fi
done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

echo -e "\n✅ Remediação finalizada"
exit 0