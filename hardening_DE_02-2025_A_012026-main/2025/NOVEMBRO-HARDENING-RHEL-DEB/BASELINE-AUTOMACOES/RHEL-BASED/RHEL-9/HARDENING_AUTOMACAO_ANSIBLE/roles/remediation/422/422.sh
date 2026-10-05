#!/usr/bin/env bash

echo -e "\n[138] Remediação – firewalld: Configurar tráfego de loopback"

# Verifica se firewalld está habilitado
if ! systemctl is-enabled firewalld.service &>/dev/null; then
    echo "⚠️ Firewalld não está habilitado – remediação não aplicável (NA)"
    exit 0
fi

# Aceita tráfego vindo da interface loopback
if ! firewall-cmd --list-interfaces --zone=trusted | grep -qw lo; then
    echo "🔹 Aplicando: aceitar tráfego da interface 'lo'..."
    firewall-cmd --permanent --zone=trusted --add-interface=lo && echo "[✅ SUCESSO]: lo adicionada à zona trusted"
    firewall-cmd --reload && echo "[✅ SUCESSO]: firewalld recarregado"
else
    echo "[✅ SUCESSO]: interface 'lo' já está permitida"
fi

# Bloqueia pacotes spoofados de 127.0.0.1 com destino diferente
echo "🔹 Aplicando regra de DROP para IPv4 spoofing..."
firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address="127.0.0.1" destination not address="127.0.0.1" drop' && echo "[✅ SUCESSO]: IPv4 spoofing bloqueado"

# Bloqueia IPv6 spoofing se IPv6 estiver ativado
if grep -q '^0$' /sys/module/ipv6/parameters/disable; then
    echo "🔹 Aplicando regra de DROP para IPv6 spoofing..."
    firewall-cmd --permanent --add-rich-rule='rule family=ipv6 source address="::1" destination not address="::1" drop' && echo "[✅ SUCESSO]: IPv6 spoofing bloqueado"
else
    echo "ℹ️ IPv6 desabilitado – regra de spoofing não necessária"
fi

# Recarrega configuração
firewall-cmd --reload && echo "[✅ SUCESSO]: firewalld recarregado"