#!/usr/bin/env bash
echo "[89 - 90] Remediação: Time Sync e Cron/At"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

echo -e "\n[89] Garantir apenas um daemon de time sync (chrony preferido)"

# Instala chrony se necessário
if ! rpm -q chrony &>/dev/null; then
    dnf install -y chrony >/dev/null 2>&1
    echo "✔ chrony instalado"
fi

# Desabilita systemd-timesyncd
if systemctl list-unit-files | grep -q systemd-timesyncd.service; then
    systemctl stop systemd-timesyncd 2>/dev/null
    systemctl disable systemd-timesyncd 2>/dev/null
    echo "✔ systemd-timesyncd desabilitado"
fi

# Habilita chronyd
systemctl enable chronyd --now >/dev/null 2>&1
echo "✔ chronyd habilitado como único daemon de tempo"
