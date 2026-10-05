#!/usr/bin/env bash
echo "108 - 115 Configure cron"
# Função para ativar o cron ou crond, conforme o sistema
ativar_cron() {
    local service_name
    service_name=$(systemctl list-unit-files | awk '$1~/^crond?\.service/{print $1}' | head -n1)

    if [[ -n "$service_name" ]]; then
        systemctl unmask "$service_name" 2>/dev/null
        if systemctl --now enable "$service_name" &>/dev/null; then
            echo "[✅ SUCESSO] Serviço '$service_name' ativado e habilitado."
        else
            echo "[❌ FALHA] Não foi possível ativar o serviço '$service_name'."
        fi
    else
        echo "[❌ FALHA] Nenhum serviço cron detectado no sistema."
    fi
}

# Função para corrigir permissões de arquivos/diretórios
corrigir_permissoes() {
    local path="$1"
    local owner="$2"
    local group="$3"
    local mode="$4"

    if [[ -e "$path" ]]; then
        chown "$owner:$group" "$path" && chmod "$mode" "$path"
        if [[ $? -eq 0 ]]; then
            echo "[✅ SUCESSO] Permissões corrigidas para $path (owner=$owner, group=$group, mode=$mode)."
        else
            echo "[❌ FALHA] Erro ao corrigir permissões em $path."
        fi
    else
        echo "[⚠️ IGNORADO] Caminho $path não existe."
    fi
}

# Início do hardening
echo "108 Ensure cron is restricted and configured securely"

ativar_cron

# Diretórios e arquivos padrão do cron
corrigir_permissoes /etc/crontab root root 600
corrigir_permissoes /etc/cron.hourly root root 700
corrigir_permissoes /etc/cron.daily root root 700
corrigir_permissoes /etc/cron.weekly root root 700
corrigir_permissoes /etc/cron.monthly root root 700
corrigir_permissoes /etc/cron.d root root 700

# Criar /etc/cron.allow se não existir
if [[ ! -e "/etc/cron.allow" ]]; then
    touch /etc/cron.allow && echo "[✅ SUCESSO] Arquivo /etc/cron.allow criado."
fi
corrigir_permissoes /etc/cron.allow root root 640

# Corrigir /etc/cron.deny se existir
corrigir_permissoes /etc/cron.deny root root 640

exit 0
