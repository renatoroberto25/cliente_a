#!/usr/bin/env bash

LOG_FILE="/var/log/dnf_check.log"
TMP_LOG="/tmp/dnf_check_temp.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

echo -e "\n [40] Certifique-se de que atualizações, patches e software de segurança adicional estejam instalados"

# Verificar atualizações pendentes
log " Verificando atualizações disponíveis..."
dnf check-update > "$TMP_LOG" 2>&1
STATUS_UPDATE=$?

if [[ $STATUS_UPDATE -eq 0 ]]; then
    log "✅ Sistema atualizado - nenhuma atualização pendente."
elif [[ $STATUS_UPDATE -eq 100 ]]; then
    log "⚠️ Atualizações disponíveis. Consulte '$TMP_LOG' para detalhes."
else
    log "❗ Erro ao verificar atualizações. Veja '$TMP_LOG'."
fi

# Verificar se o sistema requer reinicialização
log "🔁 Verificando se reinicialização é necessária..."
dnf needs-restarting -r > "$TMP_LOG" 2>&1
STATUS_RESTART=$?

if [[ $STATUS_RESTART -eq 0 ]]; then
    log "✅ Nenhuma reinicialização necessária."
else
    log "⚠️ Sistema requer reinicialização. Detalhes em '$TMP_LOG'."
fi
exit 0