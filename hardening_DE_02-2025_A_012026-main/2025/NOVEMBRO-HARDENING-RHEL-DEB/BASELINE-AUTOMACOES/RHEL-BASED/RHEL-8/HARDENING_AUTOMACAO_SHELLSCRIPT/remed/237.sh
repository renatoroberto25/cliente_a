#!/usr/bin/env bash
echo "[237] Garantir que os eventos de modificação de permissão de controle de acesso discricionário sejam coletados"

RULE_FILE="/etc/audit/rules.d/50-perm_mod.rules"
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

cat <<EOF > "$RULE_FILE"
# Regras adicionadas pela remediação 237 (HITSS Benchmark)
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=$UID_MIN -F auid!=unset -k perm_mod
-a always,exit -F arch=b64 -S chown,fchown,lchown,fchownat -F auid>=$UID_MIN -F auid!=unset -k perm_mod
-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>=$UID_MIN -F auid!=unset -k perm_mod
-a always,exit -F arch=b32 -S lchown,fchown,chown,fchownat -F auid>=$UID_MIN -F auid!=unset -k perm_mod
-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=$UID_MIN -F auid!=unset -k perm_mod
-a always,exit -F arch=b32 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=$UID_MIN -F auid!=unset -k perm_mod
EOF

augenrules --load && echo "✅ Regras aplicadas"
auditctl -s | grep -q "enabled.*2" && echo "⚠️ Reboot necessário"