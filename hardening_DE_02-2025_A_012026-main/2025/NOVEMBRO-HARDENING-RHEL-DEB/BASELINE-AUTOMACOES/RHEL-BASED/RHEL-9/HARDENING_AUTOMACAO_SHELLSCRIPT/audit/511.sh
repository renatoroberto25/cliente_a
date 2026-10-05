#!/usr/bin/env bash

echo " [143] Verificar permissões do /etc/ssh/sshd_config e arquivos complementares"

perm_mask='0177'
maxperm="$(printf '%o' $((0777 & ~$perm_mask)))"

check_perms() {
  local arq="$1"
  local out_err="" out_ok=""

  read -r mode user group < <(stat -Lc '%#a %U %G' "$arq")

  [ $((mode & perm_mask)) -gt 0 ] && \
    out_err+="  ❗ Permissão atual: $mode (esperado: $maxperm ou mais restritiva)\n"

  [ "$user" != "root" ] && \
    out_err+="  ❗ Proprietário atual: $user (esperado: root)\n"

  [ "$group" != "root" ] && \
    out_err+="  ❗ Grupo atual: $group (esperado: root)\n"

  if [ -n "$out_err" ]; then
    echo -e "⚠️ [REPROVADO] $arq\n$out_err"
  else
    echo -e "✅ [APROVADO] $arq – permissões corretas (mode: $mode, owner: $user, group: $group)"
  fi
}

# Principal
[ -f /etc/ssh/sshd_config ] && check_perms "/etc/ssh/sshd_config"

# Diretório complementar (caso exista)
if [ -d /etc/ssh/sshd_config.d ]; then
  while IFS= read -r -d '' file; do
    check_perms "$file"
  done < <(find -L /etc/ssh/sshd_config.d -type f -print0 2>/dev/null)
fi

echo -e "\n✅ Auditoria finalizada"
exit 0