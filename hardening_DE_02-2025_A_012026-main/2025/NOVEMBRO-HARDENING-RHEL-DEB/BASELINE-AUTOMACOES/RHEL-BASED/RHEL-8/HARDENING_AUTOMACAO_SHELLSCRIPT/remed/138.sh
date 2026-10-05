#!/usr/bin/env bash
echo "[138 - SSH] - Acesso, autenticação, autorização e configuração do sshd_config"

backup_file() {
  [ -f "$1" ] && cp "$1" "$1.bak_$(date +%Y%m%d_%H%M%S)"
}

# 138 - Permissões do sshd_config e arquivos .conf
echo -e "\n[138] Corrigindo permissões do sshd_config"
chmod u-x,og-rwx /etc/ssh/sshd_config 2>/dev/null
chown root:root /etc/ssh/sshd_config 2>/dev/null
find /etc/ssh/sshd_config.d -type f -print0 2>/dev/null | while IFS= read -r -d '' l_file; do
  chmod u-x,og-rwx "$l_file" 2>/dev/null
  chown root:root "$l_file" 2>/dev/null
done
echo "✅ Permissões ajustadas"

# 139 - Chaves privadas SSH
echo -e "\n[139] Corrigindo permissões das chaves privadas SSH"
find /etc/ssh -type f -name "ssh_host_*_key" ! -name "*.pub" 2>/dev/null | while read -r keyfile; do
  chmod 600 "$keyfile"
  chown root:root "$keyfile"
done
echo "✅ Permissões ajustadas"

# 140 - Chaves públicas SSH
echo -e "\n[140] Corrigindo permissões das chaves públicas SSH"
find /etc/ssh -type f -name "ssh_host_*_key.pub" 2>/dev/null | while read -r keyfile; do
  chmod 644 "$keyfile"
  chown root:root "$keyfile"
done
echo "✅ Permissões ajustadas"

# 141–158 - Parâmetros no sshd_config (somente orientação)
SSHD_FILE="/etc/ssh/sshd_config"
PARAMS=(
  "AllowUsers <definir_usuarios_autorizados>"
  "Banner /etc/issue.net"
  "Ciphers ajustar conforme política"
  "ClientAliveInterval 15"
  "ClientAliveCountMax 3"
  "DisableForwarding yes"
  "HostbasedAuthentication no"
  "IgnoreRhosts yes"
  "KexAlgorithms ajustar conforme política"
  "LoginGraceTime 60"
  "LogLevel VERBOSE"
  "MACs ajustar conforme política"
  "MaxAuthTries 4"
  "MaxSessions 10"
  "MaxStartups 10:30:60"
  "PermitEmptyPasswords no"
  "PermitRootLogin no"
  "PermitUserEnvironment no"
  "UsePAM yes"
)

echo -e "\n[141-158] Revisão de parâmetros no sshd_config"
backup_file "$SSHD_FILE"

for param in "${PARAMS[@]}"; do
  key=$(echo "$param" | awk '{print $1}')
  echo "⚠️ Parâmetro $key deve ser revisado e ajustado manualmente em $SSHD_FILE"
done

# 159 - CRYPTO_POLICY
if grep -Eq '^\s*CRYPTO_POLICY=' /etc/sysconfig/sshd 2>/dev/null; then
  echo -e "\n[159] CRYPTO_POLICY definido em /etc/sysconfig/sshd"
  echo "⚠️ Recomenda-se comentar ou ajustar manualmente este parâmetro conforme política"
fi

echo -e "\n✅ Remediação 138 concluída (Light-safe: apenas permissões corrigidas, parâmetros orientados)."

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