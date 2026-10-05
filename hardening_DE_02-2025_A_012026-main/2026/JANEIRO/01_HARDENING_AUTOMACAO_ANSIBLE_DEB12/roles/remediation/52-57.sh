#!/usr/bin/env bash
echo "[52 - 57] MAC e serviços legados"

echo -e "\n[52] Forçar SELinux para ENFORCING"

CONFIG="/etc/selinux/config"
backup "$CONFIG"

# Força ENFORCING
if grep -q '^SELINUX=' "$CONFIG"; then
    sed -i 's/^SELINUX=.*/SELINUX=enforcing/' "$CONFIG"
else
    echo "SELINUX=enforcing" >> "$CONFIG"
fi

# Garante que não está DISABLED
getenforce 2>/dev/null | grep -q "Enforcing" || setenforce 1 2>/dev/null

echo "✔ SELinux configurado como Enforcing (reboot necessário)"

echo -e "\n[53] Forçar política SELinux 'targeted'"

if grep -q '^SELINUXTYPE=' "$CONFIG"; then
    sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' "$CONFIG"
else
    echo "SELINUXTYPE=targeted" >> "$CONFIG"
fi

echo "✔ Política SELinux ajustada para targeted"

echo -e "\n[54] Remediar serviços em unconfined_service_t"

UNCONF_SVC=$(ps -eZ | awk '/unconfined_service_t/ {print $NF}' | sort -u)

if [ -n "$UNCONF_SVC" ]; then
    for svc in $UNCONF_SVC; do
        UNIT=$(systemctl status "$svc" 2>/dev/null | awk -F'[ :]' '/Loaded/ {print $5}')
        if [ -n "$UNIT" ] && [ -f "/usr/lib/systemd/system/$UNIT" ]; then
            backup "/usr/lib/systemd/system/$UNIT"
            sed -i 's/ExecStart=/SELinuxContext=system_u:system_r:init_t:s0\nExecStart=/' "/usr/lib/systemd/system/$UNIT"
            echo "✔ Serviço remediado: $svc (contexto init_t aplicado)"
        fi
    done
else
    echo "✔ Nenhum serviço em unconfined_service_t"
fi

echo -e "\n[55] Remediar processos em unconfined_t"

UNCONF_PROC=$(ps -eZ | awk '/unconfined_t/ {print $NF}' | sort -u)

if [ -n "$UNCONF_PROC" ]; then
    for p in $UNCONF_PROC; do
        systemctl stop "$p" 2>/dev/null
        systemctl disable "$p" 2>/dev/null
        echo "✔ Processo desativado por estar em unconfined_t: $p"
    done
else
    echo "✔ Nenhum processo em unconfined_t"
fi

echo -e "\n[56] Remover prelink e desfazer bibliotecas"

if rpm -q prelink &>/dev/null; then
    echo "⚠️ prelink instalado — removendo"
    prelink -ua 2>/dev/null
    dnf remove -y prelink >/dev/null 2>&1
    echo "✔ prelink desmontado e removido"
else
    echo "✔ prelink não instalado"
fi

echo -e "\n[57] Remover xinetd e arquivos residuais"

if rpm -q xinetd &>/dev/null; then
    dnf remove -y xinetd >/dev/null 2>&1
    rm -f /etc/xinetd.conf /etc/xinetd.d/* 2>/dev/null
    echo "✔ xinetd removido e diretórios limpos"
else
    echo "✔ xinetd não instalado"
fi
