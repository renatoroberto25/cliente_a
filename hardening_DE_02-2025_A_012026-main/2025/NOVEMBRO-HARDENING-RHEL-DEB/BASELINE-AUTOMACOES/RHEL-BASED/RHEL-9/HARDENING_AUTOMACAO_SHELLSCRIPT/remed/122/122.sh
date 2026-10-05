#!/usr/bin/env bash

# HITSS 40 - Auditoria e atualização de pacotes DNF com logging e verificação de reboot

LOG_FILE="/var/log/dnf_audit.log"
TMP_LOG="/tmp/dnf_audit_temp.log"

# Função para registrar saída no log e exibir na tela
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Função para verificar o status de comandos com tratamento de erro
check_command() {
    local ret_code=$1
    local msg=$2
    shift 2
    local expected_codes=("$@")

    for code in "${expected_codes[@]}"; do
        if [[ $ret_code -eq $code ]]; then
            return 0
        fi
    done

    log "❌ Erro: $msg"
    exit 1
}

log "==== INICIANDO ATUALIZAÇÕES DNF ===="

# Verifica se há atualizações disponíveis
log " Verificando pacotes disponíveis para atualização..."
dnf check-update > "$TMP_LOG" 2>&1
check_command $? "Erro ao verificar atualizações, veja o log em $TMP_LOG" 0 100

if grep -qv "No packages marked for update" "$TMP_LOG"; then
    log "📦 Atualizações disponíveis:"
    cat "$TMP_LOG" | tee -a "$LOG_FILE"
else
    log "✅ Nenhuma atualização disponível."
fi

# Aplica as atualizações do sistema
log "⚙️ Aplicando atualizações..."
dnf update -y > "$TMP_LOG" 2>&1
check_command $? "Falha ao atualizar pacotes, veja o log em $TMP_LOG" 0

# Verifica se um reboot é necessário
log "🔁 Verificando se é necessário reiniciar o sistema..."
dnf needs-restarting -r > "$TMP_LOG" 2>&1
if [[ $? -eq 1 ]]; then
    log "⚠️ O sistema preHITSSa ser reiniciado para aplicar as atualizações."
else
    log "✅ Nenhuma reinicialização necessária."
fi

# Confirma se há processos que preHITSSam de reinício
log "🔄 Verificando processos que preHITSSam de reinício..."
needs-restarting -r > "$TMP_LOG" 2>&1
if [[ $? -eq 1 ]]; then
    log "⚠️ Existem processos que preHITSSam ser reiniciados:"
    cat "$TMP_LOG" | tee -a "$LOG_FILE"
else
    log "✅ Nenhum processo pendente de reinício."
fi

log "✅ ==== ATUALIZAÇÃO FINALIZADA ===="

exit 0
