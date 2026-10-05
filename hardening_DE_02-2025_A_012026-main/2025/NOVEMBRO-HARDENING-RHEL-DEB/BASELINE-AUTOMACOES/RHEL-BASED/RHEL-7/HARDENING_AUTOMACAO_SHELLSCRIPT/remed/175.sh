#!/usr/bin/env bash
echo "[175] Remediação avançada - Restrição de uso do at (idempotente + backup)"

# Função de backup leve
backup_file() {
    local path="$1"
    [[ -e "$path" ]] && cp -p "$path" "${path}.bkp.$(date +%F_%H%M%S)" && echo "[🗂️ BACKUP] $path salvo."
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

# --- Início da remediação ---

echo "Verificando presença do pacote 'at'"
if rpm -q at &>/dev/null || dpkg -l | grep -qw at; then
    echo "[✅ OK] Pacote at instalado."
else
    echo "[⚠️ Pacote ausente] Instale manualmente com: dnf install at -y ou apt install at -y"
fi

# Garantir que o atd esteja habilitado
if systemctl list-unit-files | grep -q "^atd\.service"; then
    systemctl unmask atd &>/dev/null
    if systemctl --now enable atd &>/dev/null; then
        echo "[✅ SUCESSO] Serviço atd habilitado e em execução."
    else
        echo "[❌ FALHA] Não foi possível habilitar o serviço atd."
    fi
else
    echo "[⚠️ IGNORADO] Serviço atd não detectado neste sistema."
fi

# Criar /etc/at.allow se não existir
if [[ ! -e "/etc/at.allow" ]]; then
    touch /etc/at.allow && echo "[✅ SUCESSO] Arquivo /etc/at.allow criado."
fi
corrigir_permissoes /etc/at.allow root root 640

# Desabilitar uso de /etc/at.deny
if [[ -e "/etc/at.deny" ]]; then
    backup_file /etc/at.deny
    rm -f /etc/at.deny
    echo "[✅ SUCESSO] /etc/at.deny removido (restrição via at.allow aplicada)."
else
    echo "[ℹ️ OK] /etc/at.deny não presente — conforme esperado."
fi

echo "[ℹ️ FIM] Remediação de restrição do at concluída com sucesso."
exit 0