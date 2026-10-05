#!/usr/bin/env bash

echo -e "\n[207] Verificar integridade do PATH do usuário root"

# --- Parâmetros padrão ---
l_output2=""
l_pmask="0022"
l_maxperm="$(printf '%o' $((0777 & ~l_pmask)))"
l_root_path="$(sudo -Hiu root env | grep '^PATH=' | cut -d= -f2)"

echo "--- PATH do root: $l_root_path ---"

# --- Validações de PATH ---
grep -q "::" <<< "$l_root_path" && l_output2+="\n ⚠️ PATH contém diretório vazio (::)"
grep -qP ":\s*$" <<< "$l_root_path" && l_output2+="\n ⚠️ PATH contém separador final (:)"
grep -qP '(\s+|:)\.(:|\s*$)' <<< "$l_root_path" && l_output2+="\n ⚠️ PATH inclui diretório atual (.)"

# --- Verificações por diretório ---
IFS=":" read -ra a_path_loc <<< "$l_root_path"
for l_path in "${a_path_loc[@]}"; do
  if [[ -d "$l_path" ]]; then
    read -r l_fmode l_fown <<< "$(stat -Lc '%#a %U' "$l_path")"
    [[ "$l_fown" != "root" ]] && l_output2+="\n ⚠️ Diretório \"$l_path\" pertence a \"$l_fown\" (esperado: root)"
    [[ $((l_fmode & l_pmask)) -gt 0 ]] && l_output2+="\n ⚠️ Permissões de \"$l_path\" são $l_fmode (esperado máximo: $l_maxperm)"
  else
    l_output2+="\n ⚠️ \"$l_path\" não é um diretório válido"
  fi
done

# --- Resultado final ---
if [[ -z "$l_output2" ]]; then
  echo "✅ [APROVADO]: PATH do root está corretamente configurado"
else
  echo -e "⚠️ [REPROVADO]: Problemas encontrados:\n$l_output2"
fi

echo -e "\n❗ Atenção: se algum diretório for um symlink com permissão 777, valide o destino real."
exit 0