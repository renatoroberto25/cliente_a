#!/usr/bin/env bash
echo "250 Ensure use of privileged commands are collected"

RULE_FILE="/etc/audit/rules.d/50-privileged.rules"

# Determina UID mínimo para usuários não-sistema
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

# Identifica partições relevantes
PARTITIONS=$(findmnt -n -l -k -it "$(awk '/nodev/ { print $2 }' /proc/filesystems | paste -sd,)" | grep -Pv "noexec|nosuid" | awk '{print $1}')

# Gera regras de auditoria para cada comando privilegiado encontrado
PRIV_RULES=()
for part in $PARTITIONS; do
    while IFS= read -r file; do
        PRIV_RULES+=("-a always,exit -F path=${file} -F perm=x -F auid>=${UID_MIN} -F auid!=unset -k privileged")
    done < <(find "$part" -xdev -perm /6000 -type f 2>/dev/null)
done

# Verifica se as regras já existem
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "privileged.*path=.*perm=x.*auid>=$UID_MIN")

if [[ -n "$EXISTING_RULES" ]]; then
    echo "✅ Regras de comandos privilegiados já estão coletadas. Nenhuma alteração necessária."
    exit 0
fi

# Aplica as regras únicas no arquivo
{
    echo "# Regras adicionadas por remediação da 250 (Hitss Benchmark)"
    printf '%s\n' "${PRIV_RULES[@]}" | sort -u
} > "$RULE_FILE"

echo "✅ Regras gravadas em $RULE_FILE"

# Recarrega com augenrules
echo "Recarregando regras com augenrules..."
if augenrules --load; then
    echo "✅ Regras carregadas com sucesso."
else
    echo "❌ Erro ao carregar regras com augenrules."
fi

# Verifica se o auditd está em modo immutable
if auditctl -s | grep -q '^enabled[^0-9]*2'; then
    echo "⚠️ Reboot necessário: auditd está em modo immutable (enabled 2)"
else
    echo "✅ Regras aplicadas e carregadas com sucesso"
fi