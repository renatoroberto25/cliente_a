#!/usr/bin/env bash
set -u

echo "[89-90] Remediacao: time sync unico e cron/at"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"

backup_file() {
    local file="$1"
    [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null || true
}

echo "[89] Apenas um daemon de time sync"
echo "SKIP: escolher/desabilitar daemon de tempo exige decisao de arquitetura e janela do ambiente"

echo "[90] Cron/at seguros e restritos"
if [ -f /etc/cron.allow ]; then
    backup_file /etc/cron.allow
    if chown root:root /etc/cron.allow 2>/dev/null && chmod 0640 /etc/cron.allow 2>/dev/null; then
        echo "OK: permissoes de /etc/cron.allow ajustadas para 0640 root:root"
    else
        echo "WARN: falha ao ajustar /etc/cron.allow"
    fi
else
    if printf 'root\n' > /etc/cron.allow 2>/dev/null &&
        chown root:root /etc/cron.allow 2>/dev/null &&
        chmod 0640 /etc/cron.allow 2>/dev/null; then
        echo "OK: /etc/cron.allow criado com root e permissoes 0640"
    else
        echo "WARN: falha ao criar /etc/cron.allow"
    fi
fi

if [ -f /etc/at.allow ]; then
    backup_file /etc/at.allow
    if chown root:root /etc/at.allow 2>/dev/null && chmod 0640 /etc/at.allow 2>/dev/null; then
        echo "OK: permissoes de /etc/at.allow ajustadas para 0640 root:root"
    else
        echo "WARN: falha ao ajustar /etc/at.allow"
    fi
else
    echo "INFO: /etc/at.allow ausente; baseline deste item valida /etc/cron.allow"
fi

echo "OK"
exit 0
