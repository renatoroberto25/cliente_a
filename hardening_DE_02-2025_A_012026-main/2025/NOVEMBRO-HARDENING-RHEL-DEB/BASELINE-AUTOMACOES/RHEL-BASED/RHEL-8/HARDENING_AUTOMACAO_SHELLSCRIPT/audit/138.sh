#!/usr/bin/env bash
echo "[138 - 142] SSH - Acesso, Autenticação e Autorização"

echo -e "\n[138] Verifique se as permissões do /etc/ssh/sshd_config estão configuradas corretamente"
(stat -c "%a %n" /etc/ssh/sshd_config 2>/dev/null | grep -q "^600 " || stat -c "%a %n" /etc/ssh/sshd_config | grep -q "^640 ") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[139] Verifique se as permissões das chaves privadas do SSH estão configuradas corretamente"
(find /etc/ssh -type f -name "ssh_host_*_key" ! -perm 600 -exec ls -l {} \; | grep -q .) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[140] Verifique se as permissões das chaves públicas do SSH estão configuradas corretamente"
(find /etc/ssh -type f -name "ssh_host_*_key.pub" ! -perm 644 | grep -q .) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"


echo -e "\n[141] Verifique se o acesso ao sshd está configurado (AllowUsers, AllowGroups, DenyUsers, DenyGroups)"
grep -Eq '^\s*(AllowUsers|AllowGroups|DenyUsers|DenyGroups)\s+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[142] Verifique se o Banner do SSH está configurado"
grep -Eq '^Banner\s+/.+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


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
