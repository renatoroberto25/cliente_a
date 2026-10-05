#!/usr/bin/env bash
log() {
    echo "[✅ SUCESSO] $1"
}

err() {
    echo "[⚠️ FALHA] $1"
}
# 45 Garantir que SELinux está em modo enforcing
if sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config; then
    log "Modo SELinux configurado para enforcing (45)"
else
    err "Falha ao configurar modo enforcing (45)"
fi