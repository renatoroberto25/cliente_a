#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d_%H%M%S)"
RSYSLOG_REMOTE_CONF="/etc/rsyslog.d/60-remote.conf"
REMOTE_LOG_HOST="loghost.example.com"
CORRECT_MODE="0640"
echo "[203 - 209] Remediação rsyslog"
# 203 - Apenas avisar se não estiver instalado
if rpm -q rsyslog &>/dev/null; then
    echo "✅ rsyslog já instalado"
else
    echo "⚠️ rsyslog não está instalado — instalar manualmente se aplicável"
fi
# 204 - Enable & start rsyslog
if ! systemctl is-enabled rsyslog &>/dev/null; then
    echo "⚠️ rsyslog desabilitado — habilitar manualmente com: systemctl enable rsyslog"
fi
if ! systemctl is-active rsyslog &>/dev/null; then
    echo "⚠️ rsyslog parado — iniciar manualmente com: systemctl start rsyslog"
fi
# 205 - Configure journald to forward to rsyslog
mkdir -p /etc/systemd/journald.conf.d/
JOURNAL_CONF="/etc/systemd/journald.conf.d/99-forward-to-syslog.conf"
if ! grep -Pq '^\s*ForwardToSyslog=yes\b' "$JOURNAL_CONF" 2>/dev/null; then
    cp -p "$JOURNAL_CONF" "$JOURNAL_CONF.bak_$TS" 2>/dev/null || true
    echo "[Journal]" > "$JOURNAL_CONF"
    echo "ForwardToSyslog=yes" >> "$JOURNAL_CONF"
    systemctl restart systemd-journald
    echo "⚠️ Journald configurado para enviar logs"
else
    echo "✅ Journald já configurado"
fi
# 206 - FileCreateMode <= 0640
if rpm -q rsyslog &>/dev/null; then
    mkdir -p /etc/rsyslog.d
    if ! grep -Psiq "^\s*(\$)?FileCreateMode\s+$CORRECT_MODE\b" /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
        echo "⚠️ Adicionando FileCreateMode $CORRECT_MODE em $RSYSLOG_REMOTE_CONF"
        echo "\$FileCreateMode $CORRECT_MODE" >> "$RSYSLOG_REMOTE_CONF"
    fi
else
    echo "⚠️ rsyslog não instalado — ajuste de FileCreateMode não aplicável"
fi

# 208 - Configuração remota apenas se definido
if [[ -n "$REMOTE_LOG_HOST" ]]; then
    mkdir -p "$(dirname "$RSYSLOG_REMOTE_CONF")"
    if ! grep -q "$REMOTE_LOG_HOST" "$RSYSLOG_REMOTE_CONF" 2>/dev/null; then
        echo "⚠️ Configurando envio para host remoto: $REMOTE_LOG_HOST"
        cat <<EOF >> "$RSYSLOG_REMOTE_CONF"
*.* action(type="omfwd" target="$REMOTE_LOG_HOST" port="514" protocol="tcp" \\
           action.resumeRetryCount="100" \\
           queue.type="LinkedList" queue.size="1000")
EOF
    fi
else
    echo "ℹ️ 208 é manual — definir REMOTE_LOG_HOST antes de aplicar"
fi
# 209 - Remover recebimento remoto
for file in /etc/rsyslog.conf /etc/rsyslog.d/*.conf; do
    [[ -f "$file" ]] || continue
    if grep -Pq '^\s*(module.*load.*imtcp|input.*type=.*imtcp|\$ModLoad\s+imtcp|\$InputTCPServerRun)' "$file"; then
        cp -p "$file" "$file.bak_$TS"
        sed -i -E '/module.*load.*imtcp/s/^/#/' "$file"
        sed -i -E '/input.*type=.*imtcp/s/^/#/' "$file"
        sed -i -E '/^\s*\$ModLoad\s+imtcp/s/^/#/' "$file"
        sed -i -E '/^\s*\$InputTCPServerRun/s/^/#/' "$file"
        echo "⚠️ Entradas imtcp comentadas em $file"
    fi
done
# Restart rsyslog se instalado
if rpm -q rsyslog &>/dev/null; then
    systemctl restart rsyslog
    echo "✅ rsyslog reiniciado"
fi