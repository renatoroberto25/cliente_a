#!/usr/bin/env bash
echo "[58 - 60] Remediação: Sincronização de tempo"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

echo -e "\n[58] Garantir serviço de sincronização de tempo ativo"

# Remover timesyncd se chronyd estiver instalado (prioridade CIS/RHEL)
if systemctl list-unit-files | grep -q systemd-timesyncd.service; then
    systemctl stop systemd-timesyncd 2>/dev/null
    systemctl disable systemd-timesyncd 2>/dev/null
fi

# Instalar chrony caso não exista
if ! rpm -q chrony &>/dev/null; then
    dnf install -y chrony >/dev/null 2>&1
fi

# Garantir chronyd ativo
systemctl enable chronyd --now >/dev/null 2>&1

if systemctl is-active chronyd &>/dev/null; then
    echo "✔ Serviço de tempo ativo (chronyd)"
else
    echo "⚠️ Nenhum serviço de tempo ativo"
fi

echo -e "\n[59] Configurar Chrony corretamente"

CONF="/etc/chrony.conf"
backup "$CONF"

# Instalar se necessário
rpm -q chrony &>/dev/null || dnf install -y chrony >/dev/null 2>&1

# Habilitar e iniciar
systemctl enable chronyd --now >/dev/null 2>&1

# Adicionar servidor se faltar
if ! grep -q '^server' "$CONF"; then
    echo "server time.google.com iburst" >> "$CONF"
    echo "✔ Configurado servidor NTP padrão (time.google.com)"
fi

echo "✔ Chrony configurado"

echo -e "\n[60] Remover NTP clássico (ntpd)"

if rpm -q ntp &>/dev/null; then
    systemctl stop ntpd >/dev/null 2>&1
    systemctl disable ntpd >/dev/null 2>&1
    dnf remove -y ntp >/dev/null 2>&1
    echo "✔ NTP removido"
else
    echo "✔ NTP não está instalado"
fi


echo "OK"
exit 0
