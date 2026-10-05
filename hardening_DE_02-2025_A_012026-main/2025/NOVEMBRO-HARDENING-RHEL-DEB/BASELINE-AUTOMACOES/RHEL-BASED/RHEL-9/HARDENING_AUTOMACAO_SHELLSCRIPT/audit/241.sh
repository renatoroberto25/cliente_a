#!/usr/bin/env bash

# Verifica se o cron está instalado
verificar_instalacao_cron() {
    if rpm -q cronie &>/dev/null || dpkg -l | grep -q cron; then
echo "✅ [APROVADO]: Cron está instalado."
    else
echo "⚠️[REPROVADO]: Cron não está instalado."
    fi
}

# Verifica se o serviço cron está habilitado e ativo
verificar_servico_cron() {
    local status_enabled=$(systemctl is-enabled crond 2>/dev/null || systemctl is-enabled cron 2>/dev/null)
    local status_active=$(systemctl is-active crond 2>/dev/null || systemctl is-active cron 2>/dev/null)
    
    [[ "$status_enabled" == "enabled" ]] && echo "✅ [APROVADO]: Serviço cron está habilitado." || echo "⚠️[REPROVADO]: Serviço cron não está habilitado."
    [[ "$status_active" == "active" ]] && echo "✅ [APROVADO]: Serviço cron está ativo." || echo "⚠️[REPROVADO]: Serviço cron não está ativo."
}

# Verifica permissões e propriedade de arquivos relacionados ao cron
verificar_permissoes_cron() {
    local arquivos=(
        "/etc/crontab:600:-rw-------"
        "/etc/cron.hourly:700:drwx------"
        "/etc/cron.daily:700:drwx------"
        "/etc/cron.weekly:700:drwx------"
        "/etc/cron.monthly:700:drwx------"
        "/etc/cron.d:700:drwx------"
        "/etc/cron.allow:640:-rw-r-----"
    )
    
    for item in "${arquivos[@]}"; do
        local path=$(echo "$item" | cut -d: -f1)
        local esperado_permissao=$(echo "$item" | cut -d: -f2)
        local esperado_tipo=$(echo "$item" | cut -d: -f3)
        
        if [[ -e "$path" ]]; then
            local resultado=$(stat -Lc "%a %A" "$path")
            local permissao_atual=$(echo "$resultado" | awk '{print $1}')
            local tipo_atual=$(echo "$resultado" | awk '{print $2}')
            
            if [[ "$permissao_atual" == "$esperado_permissao" && "$tipo_atual" == "$esperado_tipo" ]]; then
echo "✅ [APROVADO]: $path está com as permissões corretas ($tipo_atual $permissao_atual)."
            else
echo "⚠️[REPROVADO]: $path está com permissões incorretas ($tipo_atual $permissao_atual), esperado ($esperado_tipo $esperado_permissao)."
            fi
        else
echo "⚠️[REPROVADO]: $path não existe."
        fi
    done
}

# Executar verificações
verificar_instalacao_cron
verificar_servico_cron
verificar_permissoes_cron