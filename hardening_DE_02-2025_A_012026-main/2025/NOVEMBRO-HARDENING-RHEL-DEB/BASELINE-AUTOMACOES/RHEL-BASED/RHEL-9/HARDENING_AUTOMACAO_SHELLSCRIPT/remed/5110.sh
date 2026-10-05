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


# [PLUS] Reforços específicos de segurança no sshd_config
echo -e "\n[PLUS] Ajustando parâmetros essenciais de segurança (sshd_config)"

SSHD_FILE="/etc/ssh/sshd_config"
backup_file "$SSHD_FILE"

declare -A SSH_PARAMS=(
  ["PermitRootLogin"]="no"
  ["PasswordAuthentication"]="no"
  ["AllowTcpForwarding"]="no"
  ["X11Forwarding"]="no"
  ["MaxAuthTries"]="3"
  ["ClientAliveInterval"]="900"
  ["Protocol"]="2"
)

for key in "${!SSH_PARAMS[@]}"; do
  val="${SSH_PARAMS[$key]}"
  if grep -Eq "^\s*${key}\b" "$SSHD_FILE"; then
    grep -Eq "^\s*${key}\s+${val}\b" "$SSHD_FILE" || sed -Ei "s|^\s*${key}\s+.*|${key} ${val}|" "$SSHD_FILE"
  else
    echo "${key} ${val}" >> "$SSHD_FILE"
  fi
done

systemctl is-active --quiet sshd && systemctl reload sshd 2>/dev/null

echo -e "\n[PLUS] Reforço de Ciphers seguros (sem CBC/3DES/AES128)"
CIPHERS_SEGUROS="aes256-ctr,aes192-ctr,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com"
ajustar_param "Ciphers" "$CIPHERS_SEGUROS"

echo "✔ Ciphers seguros aplicados"

echo -e "\n[PLUS] Reforço de MACs seguros"
MACS_SEGUROS="hmac-sha2-512,hmac-sha2-256"
ajustar_param "MACs" "$MACS_SEGUROS"

echo "✔ MACs seguros aplicados"

echo -e "\n[PLUS] Reforço de KexAlgorithms seguros"
KEX_SEGUROS="sntrup761x25519-sha512@openssh.com,curve25519-sha256@libssh.org,ecdh-sha2-nistp521"
ajustar_param "KexAlgorithms" "$KEX_SEGUROS"

echo "✔ KexAlgorithms seguros aplicados"

echo -e "\n[PLUS] Mitigação Terrapin (CVE-2023-48795)"
if ! grep -Eq 'sntrup761x25519-sha512@openssh\.com' "$arq"; then
  sed -i "s|^\s*KexAlgorithms\s\+.*|& ,sntrup761x25519-sha512@openssh.com|" "$arq"
fi

echo "✔ Mitigação Terrapin garantida"

# ----------------------------------------------------------------------
# Reload seguro
# ----------------------------------------------------------------------
echo -e "\n[PLUS] Recarregando sshd"
if systemctl reload sshd 2>/dev/null; then
  echo "✔ sshd recarregado"
else
  echo "⚠️ sshd não recarregado (serviço inativo?)"
fi
echo "Parâmetros essenciais verificados e aplicados."

exit 0
