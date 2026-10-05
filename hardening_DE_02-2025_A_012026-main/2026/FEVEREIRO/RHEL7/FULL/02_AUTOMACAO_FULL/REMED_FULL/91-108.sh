#!/usr/bin/env bash

echo -e "\n[91 - 108] Remediação: Hardening de Rede"

backup() {
    [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

SYSCTL="/etc/sysctl.d/99-hardening.conf"
[ -f "$SYSCTL" ] || touch "$SYSCTL"
backup "$SYSCTL"

set_sysctl() {
    local K="$1"
    local V="$2"

    if grep -qE "^${K}[[:space:]]*=" "$SYSCTL"; then
        sed -i "s|^${K}[[:space:]]*=.*|${K} = ${V}|" "$SYSCTL"
    else
        echo "${K} = ${V}" >> "$SYSCTL"
    fi

    sysctl -w "${K}=${V}" >/dev/null 2>&1 || true
}

echo -e "\n[91-99] Ajustes sysctl"
set_sysctl net.ipv4.ip_forward 0
set_sysctl net.ipv6.conf.all.forwarding 0
set_sysctl net.ipv4.conf.all.send_redirects 0
set_sysctl net.ipv4.conf.default.send_redirects 0
set_sysctl net.ipv4.conf.all.accept_source_route 0
set_sysctl net.ipv4.conf.default.accept_source_route 0
set_sysctl net.ipv4.conf.all.accept_redirects 0
set_sysctl net.ipv4.conf.default.accept_redirects 0
set_sysctl net.ipv4.conf.all.secure_redirects 0
set_sysctl net.ipv4.conf.default.secure_redirects 0
set_sysctl net.ipv4.conf.all.rp_filter 1
set_sysctl net.ipv4.conf.default.rp_filter 1
set_sysctl net.ipv4.icmp_echo_ignore_broadcasts 1
set_sysctl net.ipv4.icmp_ignore_bogus_error_responses 1
set_sysctl net.ipv4.tcp_syncookies 1
set_sysctl net.ipv6.conf.all.disable_ipv6 1
set_sysctl net.ipv6.conf.default.disable_ipv6 1

sysctl --system >/dev/null 2>&1 || true

echo -e "\n[100-101] ICMP timestamp drop"

if systemctl is-active --quiet firewalld 2>/dev/null; then

    firewall-cmd --permanent --add-icmp-block=timestamp-request >/dev/null 2>&1
    firewall-cmd --permanent --add-icmp-block=timestamp-reply >/dev/null 2>&1
    firewall-cmd --reload >/dev/null 2>&1
    echo " firewalld ajustado"

elif command -v iptables >/dev/null 2>&1; then

    iptables -C INPUT -p icmp --icmp-type timestamp-request -j DROP 2>/dev/null || \
    iptables -A INPUT -p icmp --icmp-type timestamp-request -j DROP

    iptables -C INPUT -p icmp --icmp-type timestamp-reply -j DROP 2>/dev/null || \
    iptables -A INPUT -p icmp --icmp-type timestamp-reply -j DROP

    echo " iptables ajustado (runtime)"

else
    echo " Nenhum firewall detectado – ação necessária do cliente"
fi

echo -e "\n[102] Wireless/Bluetooth"

MOD="/etc/modprobe.d/hardening-wireless.conf"
backup "$MOD"

cat > "$MOD" <<EOF
blacklist bluetooth
blacklist iwlwifi
install bluetooth /bin/true
install iwlwifi /bin/true
EOF

for m in bluetooth iwlwifi; do
    lsmod | awk '{print $1}' | grep -qx "$m" && modprobe -r "$m" 2>/dev/null || true
done

echo -e "\n[103-107] Firewall obrigatório"

if systemctl is-active --quiet firewalld 2>/dev/null; then
    echo " firewalld ativo – cliente deve garantir política default deny manualmente"

elif command -v iptables >/dev/null 2>&1; then
    echo " iptables presente – cliente deve garantir política default deny e persistência"

else
    echo " Nenhum firewall local ativo – NÃO conforme (instalação é decisão do cliente)"
fi

echo -e "\n[108] TLS mínimo 1.2"

if [ -d /etc/httpd ]; then
    echo " Apache detectado – revisar SSLProtocol manualmente"
fi

if [ -d /etc/nginx ]; then
    echo " Nginx detectado – revisar ssl_protocols manualmente"
fi

echo -e "\nRemediação 91–108 concluída"
