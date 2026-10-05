#!/usr/bin/env bash

echo "215 Ensure filesystem integrity is regularly checked"

# Caminhos dos arquivos
SERVICE_FILE="/etc/systemd/system/aidecheck.service"
TIMER_FILE="/etc/systemd/system/aidecheck.timer"

# Conteúdo do service
read -r -d '' SERVICE_CONTENT <<EOF
[Unit]
Description=Aide Check

[Service]
Type=simple
ExecStart=/usr/sbin/aide --check

[Install]
WantedBy=multi-user.target
EOF

# Conteúdo do timer
read -r -d '' TIMER_CONTENT <<EOF
[Unit]
Description=Aide check every day at 5AM

[Timer]
OnCalendar=*-*-* 05:00:00
Unit=aidecheck.service

[Install]
WantedBy=multi-user.target
EOF

# Criação/edição do aidecheck.service
echo "Criando ou atualizando $SERVICE_FILE..."
if echo "$SERVICE_CONTENT" > "$SERVICE_FILE"; then
    echo "✅ Arquivo aidecheck.service criado/atualizado."
else
    echo "[❌ FALHA]"
    exit 1
fi

# Criação/edição do aidecheck.timer
echo "Criando ou atualizando $TIMER_FILE..."
if echo "$TIMER_CONTENT" > "$TIMER_FILE"; then
    echo "✅ Arquivo aidecheck.timer criado/atualizado."
else
    echo "[❌ FALHA]"
    exit 1
fi

# Ajuste de permissões
echo "Ajustando permissões dos arquivos..."
if chown root:root /etc/systemd/system/aidecheck.* && chmod 0644 /etc/systemd/system/aidecheck.*; then
    echo "✅ Permissões ajustadas corretamente."
else
    echo "[❌ FALHA]"
    exit 1
fi

# Reload do systemd
echo "Recarregando systemd..."
if systemctl daemon-reload; then
    echo "✅ systemd recarregado."
else
    echo "[❌ FALHA]"
    exit 1
fi

# Habilitar o service (mesmo que o timer que chama ele, vamos seguir o CIS)
if systemctl enable --now aidecheck.service &>/dev/null; then
    echo "✅ aidecheck.service habilitado."
else
    echo "⚠️ AVISO: Não foi possível habilitar aidecheck.service."
fi

# Habilitar e iniciar o timer
if systemctl enable --now aidecheck.timer &>/dev/null; then
    echo "✅ aidecheck.timer habilitado e iniciado."
else
    echo "[❌ FALHA]"
    exit 1
fi

echo "✅ Configuração do agendamento do AIDE concluída com sucesso."
exit 0