#!/usr/bin/env bash
echo "[234] Garantir que o uso de comandos privilegiados seja coletado"

RULE_FILE="/etc/audit/rules.d/50-privileged.rules"
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

PRIV_RULES=()
for bin in $(find / -xdev -perm /6000 -type f 2>/dev/null); do
    PRIV_RULES+=("-a always,exit -F path=$bin -F perm=x -F auid>=$UID_MIN -F auid!=unset -k privileged")
done

[[ ${#PRIV_RULES[@]} -eq 0 ]] && echo "⚠️ Nenhum binário privilegiado encontrado" && exit 0

EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -q "privileged" && echo ok)
if [[ "$EXISTING_RULES" == "ok" ]]; then
    echo "✅ Já configurado."
    exit 0
fi

{
    echo "# Regras adicionadas pela remediação 234 (HITSS Benchmark)"
    printf '%s\n' "${PRIV_RULES[@]}"
} > "$RULE_FILE"

augenrules --load && echo "✅ Regras aplicadas"
auditctl -s | grep -q "enabled.*2" && echo "⚠️ Reboot necessário"