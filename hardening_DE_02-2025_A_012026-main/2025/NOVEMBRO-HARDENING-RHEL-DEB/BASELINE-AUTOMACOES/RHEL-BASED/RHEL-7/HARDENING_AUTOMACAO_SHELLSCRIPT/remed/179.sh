#!/usr/bin/env bash
echo "[179–200] Remediação de configuração do SSH"

arq="/etc/ssh/sshd_config"
bk="${arq}.bkp.$(date +%Y%m%d%H%M%S)"
cp -p "$arq" "$bk" && echo "[🗂️ BACKUP] Backup criado em $bk"

ajustar_param() {
  local chave="$1"
  local valor="$2"
  local forcar="${3:-sim}"

  if grep -iq "^[[:space:]]*${chave}[[:space:]]" "$arq"; then
    sed -i "s|^[[:space:]]*${chave}[[:space:]].*|${chave} ${valor}|" "$arq"
  elif grep -iq "^[[:space:]]*#${chave}[[:space:]]" "$arq"; then
    sed -i "s|^[[:space:]]*#${chave}[[:space:]].*|${chave} ${valor}|" "$arq"
  elif [ "$forcar" = "sim" ]; then
    echo -e "\n# Ajustado por script HITSS\n${chave} ${valor}" >> "$arq"
  fi
}

# ----------------------------------------------------------------------
# 179–181 — permissões
# ----------------------------------------------------------------------
chmod 600 "$arq" && chown root:root "$arq"

find /etc/ssh -xdev -type f -name 'ssh_host_*_key'     -exec chmod 600 {} \; -exec chown root:root {} \;
find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chmod 644 {} \; -exec chown root:root {} \;

# ----------------------------------------------------------------------
# 182–200 — parâmetros clássicos
# ----------------------------------------------------------------------
ajustar_param "AllowUsers"             "root"                "nao"
ajustar_param "LogLevel"               "VERBOSE"
ajustar_param "X11Forwarding"          "no"
ajustar_param "MaxAuthTries"           "4"
ajustar_param "IgnoreRhosts"           "yes"
ajustar_param "HostbasedAuthentication" "no"
ajustar_param "PermitRootLogin"        "no"
ajustar_param "PermitEmptyPasswords"   "no"
ajustar_param "PermitUserEnvironment"  "no"
ajustar_param "Ciphers"                "aes256-ctr,aes192-ctr,aes128-ctr"
ajustar_param "MACs"                   "hmac-sha2-512,hmac-sha2-256"
ajustar_param "KexAlgorithms"          "curve25519-sha256,ecdh-sha2-nistp521"
ajustar_param "ClientAliveInterval"    "300"
ajustar_param "ClientAliveCountMax"    "0"
ajustar_param "LoginGraceTime"         "60"
ajustar_param "Banner"                 "/etc/issue.net"
ajustar_param "UsePAM"                 "yes"
ajustar_param "AllowTcpForwarding"     "no"
ajustar_param "MaxStartups"            "10:30:60"
ajustar_param "MaxSessions"            "10"

echo "✔ Parâmetros SSH (179–200) atualizados"

# ----------------------------------------------------------------------
# PLUS — parâmetros essenciais adicionais
# ----------------------------------------------------------------------
echo -e "\n[PLUS] Ajustando parâmetros essenciais de segurança"

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
  ajustar_param "$key" "${SSH_PARAMS[$key]}"
done

echo "✔ PLUS essenciais aplicados"

# ----------------------------------------------------------------------
# PLUS — HARDENING CRIPTOGRAFIA (não duplica os anteriores)
# ----------------------------------------------------------------------

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

echo -e "\n[FINAL] Remediação completa (backup em $bk)"
exit 0
