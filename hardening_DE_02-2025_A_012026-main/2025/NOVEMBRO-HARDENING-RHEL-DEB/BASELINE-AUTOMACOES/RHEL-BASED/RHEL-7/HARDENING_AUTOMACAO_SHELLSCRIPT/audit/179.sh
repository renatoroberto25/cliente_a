#!/usr/bin/env bash
echo "[179–200] Verificações de configuração do SSH"

# 179
echo -e "\n[179] Verifique permissões de /etc/ssh/sshd_config"
stat -c "%a %U %G" /etc/ssh/sshd_config 2>/dev/null | grep -q "600 root root" && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 180
echo -e "\n[180] Verifique permissões das chaves privadas"
find /etc/ssh -xdev -type f -name 'ssh_host_*_key' ! -perm 600 -o ! -user root -o ! -group root | grep -q . && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# 181
echo -e "\n[181] Verifique permissões das chaves públicas"
find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' ! -perm 644 -o ! -user root -o ! -group root | grep -q . && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# 182
echo -e "\n[182] Verifique se SSH access é limitado"
grep -Eiq '^\s*(AllowUsers|AllowGroups|DenyUsers|DenyGroups)\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 183
echo -e "\n[183] Verifique LogLevel"
grep -Eiq '^\s*LogLevel\s+(VERBOSE|INFO)\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 184
echo -e "\n[184] Verifique X11Forwarding"
grep -Eiq '^\s*X11Forwarding\s+no\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 185
echo -e "\n[185] Verifique MaxAuthTries <= 4"
grep -Eiq '^\s*MaxAuthTries\s*[1-4]\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 186
echo -e "\n[186] Verifique IgnoreRhosts habilitado"
grep -Eiq '^\s*IgnoreRhosts\s+yes\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 187
echo -e "\n[187] Verifique HostbasedAuthentication desabilitado"
grep -Eiq '^\s*HostbasedAuthentication\s+no\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 188
echo -e "\n[188] Verifique PermitRootLogin desabilitado"
grep -Eiq '^\s*PermitRootLogin\s+no\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 189
echo -e "\n[189] Verifique PermitEmptyPasswords desabilitado"
grep -Eiq '^\s*PermitEmptyPasswords\s+no\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 190
echo -e "\n[190] Verifique PermitUserEnvironment desabilitado"
grep -Eiq '^\s*PermitUserEnvironment\s+no\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 191
echo -e "\n[191] Verifique uso de Ciphers fortes"
grep -Eiq '^\s*Ciphers\s+.*(cbc|arcfour|blowfish|cast128)' /etc/ssh/sshd_config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# 192
echo -e "\n[192] Verifique uso de MACs fortes"
grep -Eiq '^\s*MACs\s+.*(md5|sha1|ripemd160)' /etc/ssh/sshd_config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# 193
echo -e "\n[193] Verifique uso de KexAlgorithms fortes"
grep -Eiq '^\s*KexAlgorithms\s+.*(group1|sha1)' /etc/ssh/sshd_config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# 194
echo -e "\n[194] Verifique ClientAliveInterval <= 900"
grep -Eiq '^\s*ClientAliveInterval\s*(900|[1-8][0-9][0-9]|[1-9][0-9]|[1-9])\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 195
echo -E "\n[195] Verifique LoginGraceTime <= 60"
grep -Eiq '^\s*LoginGraceTime\s*(60|[1-5]?[0-9])\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 196
echo -e "\n[196] Verifique Banner"
grep -Eiq '^\s*Banner\s+/etc/issue.net\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 197
echo -e "\n[197] Verifique UsePAM habilitado"
grep -Eiq '^\s*UsePAM\s+yes\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 198
echo -e "\n[198] Verifique AllowTcpForwarding desabilitado"
grep -Eiq '^\s*AllowTcpForwarding\s+no\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 199
echo -e "\n[199] Verifique MaxStartups"
grep -Eiq '^\s*MaxStartups\s+10:30:60\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 200
echo -e "\n[200] Verifique MaxSessions <= 10"
grep -Eiq '^\s*MaxSessions\s*(10|[1-9])\b' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

####################################################
#                      PLUS
####################################################

echo -e "\n[PLUS] Verifique parâmetros essenciais do SSH"

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
  grep -Eq "$regex" /etc/ssh/sshd_config && \
    echo "✅ $key configurado corretamente" || \
    echo "⚠️ $key ausente ou incorreto"
done

echo -e "\n[PLUS] Ciphers fracos (cbc,3des,aes128)"
grep -Eiq '^\s*Ciphers\s+.*(cbc|3des|aes128)' /etc/ssh/sshd_config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[PLUS] MACs fracos (md5,sha1,umac)"
grep -Eiq '^\s*MACs\s+.*(hmac-md5|hmac-sha1|umac)' /etc/ssh/sshd_config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[PLUS] KexAlgorithms fracos (group1,group14,sha1)"
grep -Eiq '^\s*KexAlgorithms\s+.*(group1|group14|sha1)' /etc/ssh/sshd_config && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[PLUS] Mitigação Terrapin (sntrup761x25519)"
grep -Eiq '^\s*KexAlgorithms\s+.*sntrup761x25519-sha512@openssh\.com' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
