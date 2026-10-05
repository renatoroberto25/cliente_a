#!/usr/bin/env bash
echo "[91 - 99] Remediação: Hardening de Rede (sysctl)"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

SYSCTL="/etc/sysctl.d/99-hardening-network.conf"

touch "$SYSCTL"
backup "$SYSCTL"

set_sysctl() {
    KEY="$1"
    VAL="$2"

    if grep -Eq "^[[:space:]]*$KEY[[:space:]]*=" "$SYSCTL"; then
        sed -ri "s|^[[:space:]]*$KEY[[:space:]]*=.*|$KEY = $VAL|" "$SYSCTL"
    else
        echo "$KEY = $VAL" >> "$SYSCTL"
    fi

    sysctl -w "$KEY=$VAL" >/dev/null 2>&1
    echo "✔ $KEY setado para $VAL"
}

echo -e "\n[91] Desabilitar IP forwarding"
set_sysctl net.ipv4.ip_forward 0
set_sysctl net.ipv6.conf.all.forwarding 0

echo -e "\n[92] Desabilitar send_redirects"
set_sysctl net.ipv4.conf.all.send_redirects 0
set_sysctl net.ipv4.conf.default.send_redirects 0

echo -e "\n[93] Bloquear source-routed packets"
set_sysctl net.ipv4.conf.all.accept_source_route 0
set_sysctl net.ipv4.conf.default.accept_source_route 0

echo -e "\n[94] Bloquear ICMP redirects"
set_sysctl net.ipv4.conf.all.accept_redirects 0
set_sysctl net.ipv4.conf.default.accept_redirects 0
set_sysctl net.ipv4.conf.all.secure_redirects 0
set_sysctl net.ipv4.conf.default.secure_redirects 0

echo -e "\n[95] Habilitar reverse-path filtering"
set_sysctl net.ipv4.conf.all.rp_filter 1
set_sysctl net.ipv4.conf.default.rp_filter 1

echo -e "\n[96] Ignorar broadcasts ICMP"
set_sysctl net.ipv4.icmp_echo_ignore_broadcasts 1

echo -e "\n[97] Ignorar respostas ICMP inválidas"
set_sysctl net.ipv4.icmp_ignore_bogus_error_responses 1

echo -e "\n[98] Habilitar SYN cookies"
set_sysctl net.ipv4.tcp_syncookies 1

echo -e "\n[99] Desabilitar IPv6"
set_sysctl net.ipv6.conf.all.disable_ipv6 1
set_sysctl net.ipv6.conf.default.disable_ipv6 1

echo "OK"
exit 0
