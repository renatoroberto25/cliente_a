#!/usr/bin/env bash

echo " [143] Corrigir permissões do /etc/ssh/sshd_config e arquivos complementares"

data=$(date +%Y%m%d%H%M%S)

ajustar_permissao() {
  local arq="$1"
  if [ -f "$arq" ]; then
    cp -p "$arq" "${arq}.bak.${data}"
    chmod 600 "$arq"
    chown root:root "$arq"
    echo "✅ Permissões corrigidas em $arq (backup: ${arq}.bak.${data})"
  fi
}

ajustar_permissao "/etc/ssh/sshd_config"

if [ -d /etc/ssh/sshd_config.d ]; then
  while IFS= read -r -d '' arq; do
    ajustar_permissao "$arq"
  done < <(find /etc/ssh/sshd_config.d -type f -print0 2>/dev/null)
fi

echo -e "\n✅ Remediação finalizada"
exit 0