#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 109–124 (SSH – RHEL 7)"

SSHD="/etc/ssh/sshd_config"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

set_param() {
  local key="$1"
  local value="$2"

  if grep -Eiq "^[[:space:]]*${key}[[:space:]]+" "$SSHD"; then
    sed -ri "s|^[[:space:]]*${key}[[:space:]]+.*|${key} ${value}|I" "$SSHD"
  else
    echo "${key} ${value}" >> "$SSHD"
  fi
}

backup "$SSHD"

############################################
# 109 – Permissões
############################################
echo -e "\n[109] Permissões ssh"

chown root:root /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config

chown root:root /etc/ssh
chmod 750 /etc/ssh

############################################
# 111–119 – Diretivas básicas de segurança
############################################
echo -e "\n[111–119] Diretivas SSH"

set_param "SyslogFacility" "AUTHPRIV"
set_param "X11Forwarding" "no"
set_param "MaxAuthTries" "4"
set_param "IgnoreRhosts" "yes"
set_param "HostbasedAuthentication" "no"
set_param "PermitRootLogin" "prohibit-password"
set_param "PermitEmptyPasswords" "no"
set_param "PermitUserEnvironment" "no"
set_param "UsePAM" "yes"

############################################
# 120 – Idle timeout
############################################
echo -e "\n[120] Idle timeout"

set_param "ClientAliveInterval" "300"
set_param "ClientAliveCountMax" "2"

############################################
# 121 – LoginGraceTime
############################################
echo -e "\n[121] LoginGraceTime"

set_param "LoginGraceTime" "60"

############################################
# 122 – Conexões simultâneas
############################################
echo -e "\n[122] Limites de sessão"

set_param "MaxStartups" "10:30:60"
set_param "MaxSessions" "4"

############################################
# 124 – Banner (somente se já existir política)
############################################
echo -e "\n[124] Banner (não força conteúdo)"

if grep -Eiq '^[[:space:]]*Banner[[:space:]]+' "$SSHD"; then
  echo " Banner já configurado"
else
  echo " Banner não definido (política externa)"
fi

############################################
# Reload seguro
############################################
sshd -t >/dev/null 2>&1 && systemctl reload sshd >/dev/null 2>&1 || {
  echo " ERRO: configuração inválida, rollback recomendado"
}
