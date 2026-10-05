#!/usr/bin/env bash

echo " [159 - 164] Verificar configurações adicionais do sshd_config"

# 159 MaxStartups
val=$(sshd -T | awk '$1 ~ /^maxstartups/ { split($2,a,":"); print a[1], a[2], a[3] }')
IFS=' ' read -r v1 v2 v3 <<< "$val"
if [[ $v1 -le 10 && $v2 -le 30 && $v3 -le 60 ]]; then
  echo "✅ [APROVADO] MaxStartups configurado corretamente ($v1:$v2:$v3)"
else
  echo "⚠️ [REPROVADO] MaxStartups configurado como $v1:$v2:$v3 (esperado: até 10:30:60)"
fi

# 160 MaxSessions
maxsessions=$(sshd -T | awk '/^maxsessions/ {print $2}')
if [[ "$maxsessions" =~ ^[0-9]+$ && "$maxsessions" -le 10 ]]; then
  echo "✅ [APROVADO] MaxSessions configurado corretamente ($maxsessions)"
else
  echo "⚠️ [REPROVADO] MaxSessions configurado como $maxsessions (esperado: até 10)"
fi

if grep -Psiq '^\s*MaxSessions\s+(1[1-9]|[2-9][0-9])\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null; then
  echo "⚠️ [REPROVADO] MaxSessions com valor inseguro nos arquivos de configuração"
else
  echo "✅ [APROVADO] Nenhuma configuração insegura de MaxSessions nos arquivos"
fi

# 161 PermitEmptyPasswords
if sshd -T | grep -Piq 'permitemptypasswords\s+no'; then
  echo "✅ [APROVADO] PermitEmptyPasswords desativado"
else
  echo "⚠️ [REPROVADO] PermitEmptyPasswords não está desativado"
fi

if sshd -T -C user=sshuser | grep -Piq 'permitemptypasswords\s+no'; then
  echo "✅ [APROVADO] PermitEmptyPasswords desativado para blocos de correspondência"
else
  echo "⚠️ [REPROVADO] PermitEmptyPasswords não desativado no bloco de correspondência"
fi

# 162 PermitRootLogin
if sshd -T | grep -Piq 'permitrootlogin\s+no'; then
  echo "✅ [APROVADO] PermitRootLogin desativado"
else
  echo "⚠️ [REPROVADO] PermitRootLogin não está desativado"
fi

if sshd -T -C user=sshuser | grep -Piq 'permitrootlogin\s+no'; then
  echo "✅ [APROVADO] PermitRootLogin desativado para blocos de correspondência"
else
  echo "⚠️ [REPROVADO] PermitRootLogin não desativado no bloco de correspondência"
fi

# 163 PermitUserEnvironment
if sshd -T | grep -Piq 'permituserenvironment\s+no'; then
  echo "✅ [APROVADO] PermitUserEnvironment desativado"
else
  echo "⚠️ [REPROVADO] PermitUserEnvironment não está desativado"
fi

# 164 UsePAM
if sshd -T | grep -Piq 'usepam\s+yes'; then
  echo "✅ [APROVADO] UsePAM ativado"
else
  echo "⚠️ [REPROVADO] UsePAM não está ativado"
fi

echo -e "\n✅ Auditoria finalizada"
exit 0