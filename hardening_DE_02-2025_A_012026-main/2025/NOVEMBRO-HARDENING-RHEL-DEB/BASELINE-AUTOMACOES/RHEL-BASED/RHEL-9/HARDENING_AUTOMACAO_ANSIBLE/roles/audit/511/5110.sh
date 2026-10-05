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

echo -e "\n✅ Auditoria finalizada"
exit 0