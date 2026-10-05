#!/usr/bin/env bash
echo "217 Ensure journald service is enabled and active"

# Desmascarar o serviço, se necessário
if systemctl is-enabled systemd-journald.service 2>/dev/null | grep -q masked; then
    systemctl unmask systemd-journald.service
    echo "✅ Desmascarado: systemd-journald.service foi desmascarado."
else
    echo "✅ Já desmascarado: systemd-journald.service não estava mascarado."
fi

# Iniciar o serviço, se não estiver ativo
if ! systemctl is-active --quiet systemd-journald.service; then
    systemctl start systemd-journald.service
    if systemctl is-active --quiet systemd-journald.service; then
        echo "✅ Iniciado: systemd-journald.service foi iniciado com sucesso."
    else
        echo "[❌ FALHA]"
    fi
else
    echo "✅ Já em execução: systemd-journald.service já está ativo."
fi
exit 0