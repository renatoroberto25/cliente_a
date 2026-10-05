#!/usr/bin/env bash

echo " [152 - 158] Verificar parâmetros diversos do sshd_config"

# 152 DisableForwarding
if sshd -T | grep -Pi -- 'disableforwarding\s+yes' &>/dev/null; then
  echo "✅ [APROVADO] DisableForwarding está ativado"
else
  echo "⚠️ [REPROVADO] DisableForwarding não está ativado (esperado: yes)"
fi

# 153 GSSAPIAuthentication
if sshd -T | grep -Pi -- 'gssapiauthentication\s+no' &>/dev/null; then
  echo "✅ [APROVADO] GSSAPIAuthentication está desativado"
else
  echo "⚠️ [REPROVADO] GSSAPIAuthentication não está desativado (esperado: no)"
fi

# 154 HostbasedAuthentication
if sshd -T | grep -Pi -- 'hostbasedauthentication\s+no' &>/dev/null; then
  echo "✅ [APROVADO] HostbasedAuthentication está desativado"
else
  echo "⚠️ [REPROVADO] HostbasedAuthentication não está desativado (esperado: no)"
fi

# 155 IgnoreRhosts
if sshd -T | grep -Pi -- 'ignorerhosts\s+yes' &>/dev/null; then
  echo "✅ [APROVADO] IgnoreRhosts está ativado"
else
  echo "⚠️ [REPROVADO] IgnoreRhosts não está ativado (esperado: yes)"
fi

# 156 LoginGraceTime
login_grace_time=$(sshd -T | awk '/logingracetime/ {print $2}')
if [[ "$login_grace_time" =~ ^([1-9]|[1-5][0-9]|60)$ ]]; then
  echo "✅ [APROVADO] LoginGraceTime configurado corretamente ($login_grace_time)"
else
  echo "⚠️ [REPROVADO] LoginGraceTime configurado como $login_grace_time (esperado: entre 1 e 60 segundos)"
fi

# 157 LogLevel
log_level=$(sshd -T | awk '/loglevel/ {print $2}')
if [[ "$log_level" =~ ^(INFO|VERBOSE|info|verbose)$ ]]; then
  echo "✅ [APROVADO] LogLevel configurado corretamente ($log_level)"
else
  echo "⚠️ [REPROVADO] LogLevel configurado como $log_level (esperado: INFO ou VERBOSE)"
fi

# 158 MaxAuthTries
max_auth_tries=$(sshd -T | awk '/maxauthtries/ {print $2}')
if [[ "$max_auth_tries" =~ ^[1-4]$ ]]; then
  echo "✅ [APROVADO] MaxAuthTries configurado corretamente ($max_auth_tries)"
else
  echo "⚠️ [REPROVADO] MaxAuthTries configurado como $max_auth_tries (esperado: 4 ou menos)"
fi


echo -e "\n[PLUS] Verifique se parâmetros essenciais de segurança SSH estão configurados"

declare -A SSH_AUDIT_PARAMS=(
  ["PermitRootLogin"]="no|prohibit-password"
  ["PasswordAuthentication"]="no"
  ["AllowTcpForwarding"]="no"
  ["X11Forwarding"]="no"
  ["MaxAuthTries"]="3"
  ["ClientAliveInterval"]="900"
  ["Protocol"]="2"
)

for key in "${!SSH_AUDIT_PARAMS[@]}"; do
  regex="^\s*${key}\s+(${SSH_AUDIT_PARAMS[$key]})\b"
  if grep -Eq "$regex" /etc/ssh/sshd_config; then
    echo "✅ $key configurado corretamente"
  else
    echo "⚠️ $key ausente ou incorreto"
  fi
done

echo -e "\n[PLUS] Ciphers fracos (cbc,3des,aes128)"
grep -Eiq '^\s*Ciphers\s+.*(cbc|3des|aes128)' /etc/ssh/sshd_config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[PLUS] MACs fracos (md5,sha1,umac)"
grep -Eiq '^\s*MACs\s+.*(hmac-md5|hmac-sha1|umac)' /etc/ssh/sshd_config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[PLUS] KexAlgorithms fracos (group1,group14,sha1)"
grep -Eiq '^\s*KexAlgorithms\s+.*(group1|group14|sha1)' /etc/ssh/sshd_config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[PLUS] Mitigação Terrapin (sntrup761x25519)"
grep -Eiq '^\s*KexAlgorithms\s+.*sntrup761x25519-sha512@openssh\.com' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

exit 0