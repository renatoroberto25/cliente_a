#!/usr/bin/env bash

echo " [144] Verificar permissões dos arquivos de chave privada SSH"

perm_ok=true
grupo_ssh=$(awk -F: '($1 ~ /^(ssh_keys|_?ssh)$/) { print $1 }' /etc/group)
[ -z "$grupo_ssh" ] && grupo_ssh="ssh_keys"

while IFS= read -r -d '' arq; do
  if ssh-keygen -lf "$arq" &>/dev/null && file "$arq" | grep -Piq '\bopenssh.*private key\b'; then
    read -r mode owner group < <(stat -Lc '%#a %U %G' "$arq")

    [ "$group" = "$grupo_ssh" ] && mask='0137' || mask='0177'
    maxperm=$(printf '%o' $((0777 & ~$mask)))

    erros=()

    [ $((mode & mask)) -gt 0 ] && erros+=("❗ Permissão atual: $mode (esperado: $maxperm ou mais restritiva)")
    [ "$owner" != "root" ] && erros+=("❗ Proprietário atual: $owner (esperado: root)")
    [[ ! "$group" =~ ^(root|$grupo_ssh)$ ]] && erros+=("❗ Grupo atual: $group (esperado: root ou $grupo_ssh)")

    if [ ${#erros[@]} -eq 0 ]; then
      echo "✅ [APROVADO] $arq – permissões corretas (mode: $mode, owner: $owner, group: $group)"
    else
      perm_ok=false
      echo -e "⚠️ [REPROVADO] $arq"
      printf '%s\n' "${erros[@]}"
    fi
  fi
done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

$perm_ok || echo -e "\n⚠️ Um ou mais arquivos de chave privada SSH não estão em conformidade"
$perm_ok && echo -e "\n✅ Auditoria finalizada"
exit 0