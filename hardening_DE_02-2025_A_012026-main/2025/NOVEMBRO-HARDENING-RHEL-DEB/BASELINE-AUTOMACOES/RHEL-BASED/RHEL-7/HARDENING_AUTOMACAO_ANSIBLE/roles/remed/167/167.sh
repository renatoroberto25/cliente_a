#!/usr/bin/env bash
echo "[167–174] Remediação avançada - Cron e At (idempotente + backup)"

# Função de backup leve
backup_file() {
    local path="$1"
    [[ -e "$path" ]] && cp -p "$path" "${path}.bkp.$(date +%F_%H%M%S)" && echo "[🗂️ BACKUP] $path salvo."
}

# Função para ativar cron
ativar_cron() {
    local service_name
    service_name=$(systemctl list-unit-files | awk '$1~/^crond?\.service/{print $1}' | head -n1)
    if [[ -n "$service_name" ]]; then
        systemctl unmask "$service_name" &>/dev/null
        if systemctl --now enable "$service_name" &>/dev/null; then
            echo "[✅ SUCESSO] Serviço '$service_name' habilitado e em execução."
        else
            echo "[❌ FALHA] Não foi possível ativar '$service_name'."
        fi
    else
        echo "[⚠️ IGNORADO] Nenhum serviço cron detectado."
    fi
}

# Função para corrigir permissões idempotente
corrigir_permissoes() {
    local path="$1"
    local owner="$2"
    local group="$3"
    local mode="$4"
    if [[ -e "$path" ]]; then
        local current_mode current_owner current_group
        current_mode=$(stat -c "%a" "$path")
        current_owner=$(stat -c "%U" "$path")
        current_group=$(stat -c "%G" "$path")
        if [[ "$current_mode" == "$mode" && "$current_owner" == "$owner" && "$current_group" == "$group" ]]; then
            echo "[ℹ️ OK] $path já conforme (owner=$owner, group=$group, mode=$mode)"
        else
            backup_file "$path"
            chown "$owner:$group" "$path" && chmod "$mode" "$path"
            echo "[✅ SUCESSO] Permissões corrigidas em $path (owner=$owner, group=$group, mode=$mode)"
        fi
    else
        echo "[⚠️ IGNORADO] $path não existe."
    fi
}

# Execução
ativar_cron
corrigir_permissoes /etc/crontab root root 600
corrigir_permissoes /etc/cron.hourly root root 700
corrigir_permissoes /etc/cron.daily root root 700
corrigir_permissoes /etc/cron.weekly root root 700
corrigir_permissoes /etc/cron.monthly root root 700
corrigir_permissoes /etc/cron.d root root 700

# Criar /etc/cron.allow se não existir
if [[ ! -e "/etc/cron.allow" ]]; then
    touch /etc/cron.allow && echo "[✅ SUCESSO] /etc/cron.allow criado."
fi
corrigir_permissoes /etc/cron.allow root root 640

# Corrigir deny — agora remove em vez de ajustar
[[ -e /etc/cron.deny ]] && cp -p /etc/cron.deny /etc/cron.deny.bkp.$(date +%F_%H%M%S) && rm -f /etc/cron.deny && echo "[✅ SUCESSO] /etc/cron.deny removido (restrição via cron.allow aplicada)" || echo "[ℹ️ OK] /etc/cron.deny não presente — conforme esperado"

echo "[ℹ️ FIM] Remediação de cron concluída com sucesso."
exit 0