#!/usr/bin/env bash

echo " [145] Verificar permissões dos arquivos de chave pública SSH"

perm_ok=true
pmask='0133'
maxperm=$(printf '%o' $((0777 & ~$pmask)))

while IFS= read -r -d '' arq; do
  if ssh-keygen -lf "$arq" &>/dev/null && file "$arq" | grep -Piq '\bopenssh.*public key\b'; then
    read -r mode owner group < <(stat -Lc '%#a %U %G' "$arq")

    erros=()

    [ $((mode & pmask)) -gt 0 ] && erros+=("❗ Permissão atual: $mode (esperado: $maxperm ou mais restritiva)")
    [ "$owner" != "root" ] && erros+=("❗ Proprietário atual: $owner (esperado: root)")
    [ "$group" != "root" ] && erros+=("❗ Grupo atual: $group (esperado: root)")

    if [ ${#erros[@]} -eq 0 ]; then
      echo "✅ [APROVADO] $arq – permissões corretas (mode: $mode, owner: $owner, group: $group)"
    else
      perm_ok=false
      echo -e "⚠️ [REPROVADO] $arq"
      printf '%s\n' "${erros[@]}"
    fi
  fi
done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

$perm_ok || echo -e "\n⚠️ Um ou mais arquivos de chave pública SSH não estão em conformidade"
$perm_ok && echo -e "\n✅ Auditoria finalizada"
exit 0