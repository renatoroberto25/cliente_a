#!/usr/bin/env bash
#Script em estilo tardio, desenvolvido no fim do repo ful, por isso pode parecer muito diferente dos demais
#Meu entendimento é que em remediação não é sucesso e reprovado, e sim falha ou sucesso.
log() {
    echo "[✅ SUCESSO] $1"
}

err() {
    echo "[⚠️ FALHA] $1"
}

# 41 Garantir que o SELinux está instalado
if dnf install -y libselinux &>/dev/null; then
    log "SELinux instalado com sucesso"
else
    err "Falha ao instalar SELinux"
fi

# 42 Garantir que o SELinux não está desabilitado no bootloader
if grubby --update-kernel ALL --remove-args "selinux=0 enforcing=0" &>/dev/null; then
    log "SELinux habilitado no bootloader"
else
    err "Falha ao configurar SELinux no bootloader"
fi

# 43 Garantir que a política SELinux está configurada
if sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' /etc/selinux/config; then
    log "Política SELinux configurada como 'targeted'"
else
    err "Falha ao configurar política SELinux"
fi

# 44 Garantir que o SELinux está em enforcing
if sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config; then
    log "Modo SELinux configurado para enforcing (requer reboot)"
else
    err "Falha ao configurar modo enforcing"
fi

# feito a parte por ser LEVEL 2
# 45 Garantir que SELinux está em modo enforcing
#if sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config; then
#    log "Modo SELinux configurado para enforcing (45)"
#else
#    err "Falha ao configurar modo enforcing (45)"
#fi

# 46 Garantir que não existem serviços sem restrição - Nível 2
log "Verificando serviços com contexto unconfined_service_t"
if ps -eZ | grep -q unconfined_service_t; then
    err "Serviços sem restrição encontrados: revisar contexto SELinux"
else
    log "Nenhum serviço sem restrição encontrado"
fi

# 47 Garantir que o mcstrans não está instalado
if dnf remove -y mcstrans &>/dev/null; then
    log "mcstrans removido ou não instalado"
else
    err "Falha ao remover mcstrans"
fi

# 48 Garantir que o setroubleshoot não está instalado
if dnf remove -y setroubleshoot &>/dev/null; then
    log "setroubleshoot removido ou não instalado"
else
    err "Falha ao remover setroubleshoot"
fi
