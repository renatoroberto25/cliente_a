#!/usr/bin/env bash
echo -e "\n[160] Verifique se os Ciphers estão configurados"
grep -Eq '^\s*Ciphers\s+.+$' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[161] Verifique se ClientAliveInterval e ClientAliveCountMax estão configurados"
( grep -Eq '^\s*ClientAliveInterval\s+[0-9]+' /etc/ssh/sshd_config && \
  grep -Eq '^\s*ClientAliveCountMax\s+[0-9]+' /etc/ssh/sshd_config ) \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[162] Verifique se DisableForwarding está ativado"
grep -Eq '^\s*DisableForwarding\s+yes' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[163] Verifique se GSSAPIAuthentication está desabilitado"
grep -Eq '^\s*GSSAPIAuthentication\s+no' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[164] Verifique se HostbasedAuthentication está desabilitado"
grep -Eq '^\s*HostbasedAuthentication\s+no' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[165] Verifique se IgnoreRhosts está habilitado"
grep -Eq '^\s*IgnoreRhosts\s+yes' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[166] Verifique se os KexAlgorithms estão configurados"
grep -Eq '^\s*KexAlgorithms\s+.+$' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[167] Verifique se LoginGraceTime está configurado"
grep -Eq '^\s*LoginGraceTime\s+[0-9]+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[168] Verifique se LogLevel está configurado"
grep -Eq '^\s*LogLevel\s+(INFO|VERBOSE)' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[169] Verifique se os MACs estão configurados"
grep -Eq '^\s*MACs\s+.+$' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[170] Verifique se MaxAuthTries está configurado"
grep -Eq '^\s*MaxAuthTries\s+[0-9]+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[171] Verifique se MaxSessions está configurado"
grep -Eq '^\s*MaxSessions\s+[0-9]+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[172] Verifique se MaxStartups está configurado"
grep -Eq '^\s*MaxStartups\s+.+$' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[173] Verifique se PermitEmptyPasswords está desabilitado"
grep -Eq '^\s*PermitEmptyPasswords\s+no' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[174] Verifique se PermitRootLogin está desabilitado"
grep -Eq '^\s*PermitRootLogin\s+no' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[175] Verifique se PermitUserEnvironment está desabilitado"
grep -Eq '^\s*PermitUserEnvironment\s+no' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

####################################################
#                    PLUS – ESSENCIAIS
####################################################

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
  grep -Eq "$regex" /etc/ssh/sshd_config \
    && echo "✅ $key configurado corretamente" \
    || echo "⚠️ $key ausente ou incorreto"
done

####################################################
#             PLUS – CRIPTOGRAFIA SSH
####################################################

echo -e "\n[PLUS] Verifique Ciphers fracos (cbc,3des,aes128)"
grep -Eiq '^\s*Ciphers\s+.*(cbc|3des|aes128)' /etc/ssh/sshd_config \
  && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[PLUS] Verifique MACs fracos (md5,sha1,umac)"
grep -Eiq '^\s*MACs\s+.*(hmac-md5|hmac-sha1|umac)' /etc/ssh/sshd_config \
  && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[PLUS] Verifique KexAlgorithms fracos (group1,group14,sha1)"
grep -Eiq '^\s*KexAlgorithms\s+.*(group1|group14|sha1)' /etc/ssh/sshd_config \
  && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[PLUS] Verifique mitigação Terrapin (sntrup761x25519)"
grep -Eiq '^\s*KexAlgorithms\s+.*sntrup761x25519-sha512@openssh\.com' /etc/ssh/sshd_config \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
