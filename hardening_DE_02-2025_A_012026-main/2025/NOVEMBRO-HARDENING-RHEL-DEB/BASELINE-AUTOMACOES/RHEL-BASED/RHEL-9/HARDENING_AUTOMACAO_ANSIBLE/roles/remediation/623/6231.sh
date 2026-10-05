#!/usr/bin/env bash

RSYSLOG_REMOTE_CONF="/etc/rsyslog.d/60-remote.conf"
REMOTE_LOG_HOST="loghost.example.com"
CORRECT_MODE="0640"

echo "228 Ensure rsyslog is installed"
if ! rpm -q rsyslog &>/dev/null; then
    echo "Instalando rsyslog..."
    dnf install -y rsyslog || yum install -y rsyslog
else
    echo "✅ rsyslog já está instalado"
fi

echo "229 Habilitando e iniciando rsyslog..."
systemctl enable rsyslog.service
systemctl start rsyslog.service

echo "230 Configurando journald para enviar logs ao rsyslog..."
mkdir -p /etc/systemd/journald.conf.d/
cat > /etc/systemd/journald.conf.d/99-forward-to-syslog.conf <<EOF
[Journal]
ForwardToSyslog=yes
EOF
systemctl restart systemd-journald

echo "231 Corrigindo FileCreateMode para $CORRECT_MODE..."
# Comenta configurações incorretas
find /etc/rsyslog.d/ -type f -name '*.conf' -exec sed -i \
    -E "/^\s*(\\$)?FileCreateMode\s*(=|\s)\s*['\"]?(0[0-7]{3})['\"]?/ {
        /$CORRECT_MODE/! s/^/# /
    }" {} +

sed -i -E "/^\s*FileCreateMode\s*(=|\s)\s*['\"]?(0[0-7]{3})['\"]?/ {
    /$CORRECT_MODE/! s/^/# /
}" /etc/rsyslog.conf

# Adiciona FileCreateMode correto se não houver
if ! grep -Psiq "^\s*(\\$)?FileCreateMode\s*(=|\s)\s*['\"]?$CORRECT_MODE['\"]?" /etc/rsyslog.conf /etc/rsyslog.d/*.conf; then
    echo "Adicionando FileCreateMode $CORRECT_MODE ao início de $RSYSLOG_REMOTE_CONF"
    sed -i "1i\\$FileCreateMode $CORRECT_MODE" "$RSYSLOG_REMOTE_CONF"
fi

echo "233 Garantindo configuração de envio remoto..."
mkdir -p "$(dirname "$RSYSLOG_REMOTE_CONF")"
if ! grep -q "omfwd" "$RSYSLOG_REMOTE_CONF" 2>/dev/null; then
    cat <<EOF >> "$RSYSLOG_REMOTE_CONF"
*.* action(type="omfwd" target="$REMOTE_LOG_HOST" port="514" protocol="tcp" \\
           action.resumeRetryCount="100" \\
           queue.type="LinkedList" queue.size="1000")
EOF
fi

echo "234 Removendo entradas que escutam logs remotos..."
sed -i '/module.*load.*imtcp/ s/^/#/' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null || true
sed -i '/input.*type=.*imtcp/ s/^/#/' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null || true

## Reinicia o serviço
echo "Reiniciando rsyslog..."
systemctl restart rsyslog && echo "✅ rsyslog reiniciado."