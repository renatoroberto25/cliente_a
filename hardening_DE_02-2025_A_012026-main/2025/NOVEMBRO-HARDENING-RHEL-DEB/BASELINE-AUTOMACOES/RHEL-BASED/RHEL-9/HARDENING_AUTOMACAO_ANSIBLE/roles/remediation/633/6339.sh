#!/usr/bin/env bash
echo "253 Ensure discretionary access control permission modification events are collected"

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

if [[ -z "$UID_MIN" ]]; then
  echo "❌ ERRO: UID_MIN não encontrado em /etc/login.defs"
  exit 1
fi

# Arquivos para verificar
files_to_check=()
[[ -f /etc/audit/audit.rules ]] && files_to_check+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && files_to_check+=("/etc/audit/rules.d/"*.rules)

# Regex robusta para todas as syscalls e combinações
REGEX="^-a\s+always,exit.*arch=b(32|64).*auid>=$UID_MIN.*auid!=unset.*-S\s+.*(chmod|chown|setxattr|removexattr).*key\s*=\s*perm_mod"

# Verifica disco
DISK_OK=$(grep -P "$REGEX" "${files_to_check[@]}" 2>/dev/null)

# Verifica regras carregadas
RUNTIME_OK=$(auditctl -l 2>/dev/null | grep -P "$REGEX")

if [[ -n "$DISK_OK" || -n "$RUNTIME_OK" ]]; then
  echo "✅ As regras já existem. Nenhuma modificação necessária."
else
  echo "⚠️ Regras ausentes. Aplicando configuração..."

  cat <<EOF > /etc/audit/rules.d/50-perm_mod.rules
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=$UID_MIN -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b64 -S chown,fchown,lchown,fchownat -F auid>=$UID_MIN -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>=$UID_MIN -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S lchown,fchown,chown,fchownat -F auid>=$UID_MIN -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=$UID_MIN -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=$UID_MIN -F auid!=unset -F key=perm_mod
EOF

  echo "Regras salvas em /etc/audit/rules.d/50-perm_mod.rules"
  echo "Carregando regras com augenrules..."
  augenrules --load

  if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    echo "⚠️ Reboot necessário para carregar as regras (audit em modo immutable)"
  else
    echo "✅ Regras carregadas com sucesso"
  fi
fi