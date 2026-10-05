#!/usr/bin/env bash

echo " [159 a 164] Corrigir parâmetros no /etc/ssh/sshd_config"

arq="/etc/ssh/sshd_config"
bk="${arq}.bak.$(date +%Y%m%d%H%M%S)"
cp -p "$arq" "$bk"

ajustar_param() {
  local chave="$1"
  local valor="$2"

  grep -iEq "^\s*${chave}\s+" "$arq" && \
    sed -i "s|^\s*${chave}\s\+.*|${chave} ${valor}|" "$arq" || \
    echo -e "\n# Adicionado por script de remediação\n${chave} ${valor}" >> "$arq"
}

ajustar_param "MaxStartups" "10:30:60"           # 159
ajustar_param "MaxSessions" "10"                 # 160
ajustar_param "PermitEmptyPasswords" "no"        # 161
ajustar_param "PermitRootLogin" "no"             # 162
ajustar_param "PermitUserEnvironment" "no"       # 163
ajustar_param "UsePAM" "yes"                     # 164

echo "✅ Parâmetros atualizados (backup: $bk)"
echo "⚠️ Reinício do sshd necessário para aplicar alterações"
# systemctl restart sshd  # comentar por segurança

echo -e "\n✅ Remediação finalizada"
exit 0