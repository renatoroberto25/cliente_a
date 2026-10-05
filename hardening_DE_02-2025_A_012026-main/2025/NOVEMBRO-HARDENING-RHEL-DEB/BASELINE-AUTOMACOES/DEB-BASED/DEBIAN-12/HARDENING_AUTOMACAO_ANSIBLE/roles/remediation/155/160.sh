#!/usr/bin/env bash
echo "[160 - 175] SSH - Remediação de parâmetros do sshd_config"

SSHD_FILE="/etc/ssh/sshd_config"
BACKUP="$SSHD_FILE.bak_$(date +%Y%m%d_%H%M%S)"

backup_file() {
  [ -f "$SSHD_FILE" ] && cp "$SSHD_FILE" "$BACKUP" && echo "❗ Backup criado em $BACKUP"
}

# Cria backup antes de alterar qualquer coisa
backup_file

# Função para ajustar ou inserir parâmetros no sshd_config
set_param() {
  local key="$1"
  local value="$2"
  if grep -qE "^\s*${key}\s+" "$SSHD_FILE"; then
    sed -i "s|^\s*${key}\s\+.*|${key} ${value}|" "$SSHD_FILE"
  else
    echo "${key} ${value}" >> "$SSHD_FILE"
  fi
}

# 160 - Ciphers
echo -e "\n[160] Corrigindo Ciphers"
set_param "Ciphers" "aes256-ctr,aes192-ctr,aes128-ctr"
echo "✅ Ajustado Ciphers seguros"

# 161 - ClientAliveInterval e ClientAliveCountMax
echo -e "\n[161] Corrigindo ClientAliveInterval e ClientAliveCountMax"
set_param "ClientAliveInterval" "15"
set_param "ClientAliveCountMax" "3"
echo "✅ Ajustado para ClientAliveInterval 15 e ClientAliveCountMax 3"

# 162 - DisableForwarding
echo -e "\n[162] Corrigindo DisableForwarding"
set_param "DisableForwarding" "yes"
echo "✅ Ajustado DisableForwarding yes"

# 163 - GSSAPIAuthentication
echo -e "\n[163] Corrigindo GSSAPIAuthentication"
set_param "GSSAPIAuthentication" "no"
echo "✅ Ajustado GSSAPIAuthentication no"

# 164 - HostbasedAuthentication
echo -e "\n[164] Corrigindo HostbasedAuthentication"
set_param "HostbasedAuthentication" "no"
echo "✅ Ajustado HostbasedAuthentication no"

# 165 - IgnoreRhosts
echo -e "\n[165] Corrigindo IgnoreRhosts"
set_param "IgnoreRhosts" "yes"
echo "✅ Ajustado IgnoreRhosts yes"

# 166 - KexAlgorithms
echo -e "\n[166] Corrigindo KexAlgorithms"
set_param "KexAlgorithms" "curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256"
echo "✅ Ajustado KexAlgorithms seguros"

# 167 - LoginGraceTime
echo -e "\n[167] Corrigindo LoginGraceTime"
set_param "LoginGraceTime" "60"
echo "✅ Ajustado LoginGraceTime 60"

# 168 - LogLevel
echo -e "\n[168] Corrigindo LogLevel"
set_param "LogLevel" "VERBOSE"
echo "✅ Ajustado LogLevel VERBOSE"

# 169 - MACs
echo -e "\n[169] Corrigindo MACs"
set_param "MACs" "hmac-sha2-512,hmac-sha2-256"
echo "✅ Ajustado MACs seguros"

# 170 - MaxAuthTries
echo -e "\n[170] Corrigindo MaxAuthTries"
set_param "MaxAuthTries" "4"
echo "✅ Ajustado MaxAuthTries 4"

# 171 - MaxSessions
echo -e "\n[171] Corrigindo MaxSessions"
set_param "MaxSessions" "10"
echo "✅ Ajustado MaxSessions 10"

# 172 - MaxStartups
echo -e "\n[172] Corrigindo MaxStartups"
set_param "MaxStartups" "10:30:60"
echo "✅ Ajustado MaxStartups 10:30:60"

# 173 - PermitEmptyPasswords
echo -e "\n[173] Corrigindo PermitEmptyPasswords"
set_param "PermitEmptyPasswords" "no"
echo "✅ Ajustado PermitEmptyPasswords no"

# 174 - PermitRootLogin
echo -e "\n[174] Corrigindo PermitRootLogin"
set_param "PermitRootLogin" "no"
echo "✅ Ajustado PermitRootLogin no"

# 175 - PermitUserEnvironment
echo -e "\n[175] Corrigindo PermitUserEnvironment"
set_param "PermitUserEnvironment" "no"
echo "✅ Ajustado PermitUserEnvironment no"

# Testa e recarrega sshd
echo -e "\nValidando configuração do SSH..."
if sshd -t 2>/dev/null; then
  echo "✅ Configuração válida"
  systemctl reload sshd && echo "✅ sshd recarregado com sucesso"
else
  echo "⚠️ Erro na configuração do SSH. Verifique $SSHD_FILE ou o backup em $BACKUP"
  exit 1
fi

############################################################
#                      PLUS — ESSENCIAIS
############################################################

echo -e "\n[PLUS] Ajustando parâmetros essenciais de segurança SSH"

declare -A PLUS_PARAMS=(
  ["PermitRootLogin"]="no"
  ["PasswordAuthentication"]="no"
  ["AllowTcpForwarding"]="no"
  ["X11Forwarding"]="no"
  ["MaxAuthTries"]="3"
  ["ClientAliveInterval"]="900"
  ["Protocol"]="2"
)

for key in "${!PLUS_PARAMS[@]}"; do
  val="${PLUS_PARAMS[$key]}"
  echo "Aplicando $key $val"
  set_param "$key" "$val"
done

echo "✔ PLUS essenciais aplicados"


############################################################
#         PLUS — HARDENING DE CRIPTOGRAFIA (Debian)
############################################################

echo -e "\n[PLUS] Ciphers seguros (substituindo CBC/3DES/AES128 fracos)"
CIPHERS_SEGUROS="aes256-ctr,aes192-ctr,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com"
set_param "Ciphers" "$CIPHERS_SEGUROS"
echo "✔ Ciphers atualizados para política segura"


echo -e "\n[PLUS] MACs seguros (removendo md5/sha1/umac fracos)"
MACS_SEGUROS="hmac-sha2-512,hmac-sha2-256"
set_param "MACs" "$MACS_SEGUROS"
echo "✔ MACs atualizados"


echo -e "\n[PLUS] KexAlgorithms seguros"
KEX_SEGUROS="sntrup761x25519-sha512@openssh.com,curve25519-sha256@libssh.org,ecdh-sha2-nistp521"
set_param "KexAlgorithms" "$KEX_SEGUROS"
echo "✔ KexAlgorithms atualizados"


echo -e "\n[PLUS] Mitigação Terrapin (CVE-2023-48795)"
if ! grep -Eq 'sntrup761x25519-sha512@openssh\.com' "$SSHD_FILE"; then
  sed -i "s|^\s*KexAlgorithms\s\+.*|& ,sntrup761x25519-sha512@openssh.com|" "$SSHD_FILE"
fi
echo "✔ Mitigação Terrapin garantida"


############################################################
#               Reload / Validação Debian
############################################################

echo -e "\nValidando configuração do SSH..."
if sshd -t 2>/dev/null; then
  echo "✔ Configuração válida"
  systemctl reload sshd && echo "✔ sshd recarregado com sucesso"
else
  echo "⚠️ Erro na configuração do SSH. Verifique $SSHD_FILE ou o backup em $BACKUP"
  exit 1
fi

echo -e "\n[FINAL] Remediação Debian concluída (backup em $BACKUP)"
exit 0
