#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: sincronizacao de tempo"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para avaliar remediacoes"
    exit 0
fi

unit_active() {
    systemctl is-active --quiet "$1" >/dev/null 2>&1
}

unit_enabled() {
    systemctl is-enabled "$1" >/dev/null 2>&1
}

has_time_source() {
    local conf="$1"
    [ -f "$conf" ] && grep -Eq '^[[:space:]]*(server|pool)[[:space:]]+\S+' "$conf"
}

echo "[58] Sincronizacao de tempo em uso"
if unit_active chronyd || unit_active ntpd || unit_active systemd-timesyncd; then
    echo "OK: algum servico de sincronizacao de tempo esta ativo"
else
    echo "SKIP: nenhum servico de tempo ativo; habilitar servico exige decisao de arquitetura/janela"
fi

echo "[59] Fontes NTP/Chrony configuradas"
if has_time_source /etc/chrony.conf; then
    echo "OK: /etc/chrony.conf possui server/pool configurado"
elif has_time_source /etc/ntp.conf; then
    echo "OK: /etc/ntp.conf possui server/pool configurado"
else
    echo "SKIP: fonte de tempo nao definida; nao inserir servidor NTP padrao sem aprovacao"
fi

echo "[60] Sincronizacao de tempo habilitada no boot"
if unit_enabled chronyd || unit_enabled ntpd || unit_enabled systemd-timesyncd; then
    echo "OK: algum servico de sincronizacao de tempo esta habilitado no boot"
else
    echo "SKIP: nenhum servico de tempo habilitado; enable/start requer aprovacao do ambiente"
fi

echo "OK"
exit 0
