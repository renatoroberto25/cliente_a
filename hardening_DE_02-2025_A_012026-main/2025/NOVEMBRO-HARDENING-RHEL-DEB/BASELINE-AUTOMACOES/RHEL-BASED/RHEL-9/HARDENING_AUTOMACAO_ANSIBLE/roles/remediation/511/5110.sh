#!/usr/bin/env bash

echo -e "\n[152 - 158] Remediar parâmetros diversos do sshd_config"

arq="/etc/ssh/sshd_config"
bk="${arq}.bak.$(date +%Y%m%d%H%M%S)"
cp -p "$arq" "$bk" && echo "🗂️ Backup criado: $bk"

ajustar_param() {
  local chave="$1"
  local valor="$2"

  if grep -iEq "^\s*${chave}\s+" "$arq"; then
    sed -i "s|^\s*${chave}\s\+.*|${chave} ${valor}|" "$arq"
  elif grep -iEq "^\s*#\s*${chave}\s+" "$arq"; then
    sed -i "s|^\s*#\s*${chave}\s\+.*|${chave} ${valor}|" "$arq"
  else
    echo -e "\n# Adicionado por script de remediação\n${chave} ${valor}" >> "$arq"
  fi
}

# 152 DisableForwarding ou parâmetros equivalentes
if sshd -T 2>/dev/null | grep -q disableforwarding; then
  ajustar_param "DisableForwarding" "yes"
else
  ajustar_param "AllowTcpForwarding" "no"
  ajustar_param "AllowAgentForwarding" "no"
  ajustar_param "PermitOpen" "none"
fi

# 153
ajustar_param "GSSAPIAuthentication" "no"

# 154
ajustar_param "HostbasedAuthentication" "no"

# 155
ajustar_param "IgnoreRhosts" "yes"

# 156
ajustar_param "LoginGraceTime" "60"

# 157
ajustar_param "LogLevel" "VERBOSE"

# 158
ajustar_param "MaxAuthTries" "4"

echo "✅ Parâmetros atualizados com sucesso"
echo "⚠️ Reinício do sshd necessário para aplicar alterações"
# systemctl restart sshd

echo -e "\n✅ Remediação finalizada"
exit 0
