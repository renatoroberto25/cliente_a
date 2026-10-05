#!/usr/bin/env bash
echo "[91 - 108] Remediação: Hardening de Rede"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

SYSCTL="/etc/sysctl.d/99-hardening.conf"
touch "$SYSCTL"
backup "$SYSCTL"

set_sysctl() {
    KEY="$1"
    VAL="$2"
    if grep -q "^$KEY" "$SYSCTL"; then
        sed -i "s/^$KEY.*/$KEY = $VAL/" "$SYSCTL"
    else
        echo "$KEY = $VAL" >> "$SYSCTL"
    fi
    sysctl -w "$KEY=$VAL" >/dev/null 2>&1
    echo "✔ $KEY = $VAL"
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

echo -e "\n[96] Ignorar ICMP broadcasts"
set_sysctl net.ipv4.icmp_echo_ignore_broadcasts 1

echo -e "\n[97] Ignorar respostas ICMP inválidas"
set_sysctl net.ipv4.icmp_ignore_bogus_error_responses 1

echo -e "\n[98] Habilitar SYN cookies"
set_sysctl net.ipv4.tcp_syncookies 1

echo -e "\n[99] IPv6 — AUDIT ONLY (não remediado no Debian 12)"

# ---------------------------------------------------------
# ICMP timestamp — aplicar somente se backend existir
# ---------------------------------------------------------
echo -e "\n[100-101] Bloquear ICMP timestamp (request/reply)"

apply_icmp_rule() {
    TYPE="$1"

    # nftables (preferencial no Debian 12)
    if command -v nft &>/dev/null && nft list ruleset 2>/dev/null | grep -q 'table inet'; then
        nft list ruleset | grep -Eq "icmp type $TYPE.*drop" || \
        nft add rule inet filter input icmp type "$TYPE" drop &>/dev/null
        echo "✔ nftables: $TYPE"
        return
    fi

    # iptables fallback
    if command -v iptables &>/dev/null; then
        iptables -C INPUT -p icmp --icmp-type "$TYPE" -j DROP 2>/dev/null || \
        iptables -A INPUT -p icmp --icmp-type "$TYPE" -j DROP
        echo "✔ iptables: $TYPE"
        return
    fi

    echo "⚠️ Nenhum firewall backend disponível para $TYPE"
}

apply_icmp_rule timestamp-request
apply_icmp_rule timestamp-reply

echo -e "\n[102] Wireless/Bluetooth — remediação condicional"

if ! systemctl is-active display-manager &>/dev/null; then
    for m in bluetooth iwlwifi; do
        modinfo "$m" &>/dev/null || continue
        lsmod | grep -q "^$m" && modprobe -r "$m" 2>/dev/null
    done

    MODFILE="/etc/modprobe.d/hardening-wireless.conf"
    backup "$MODFILE"
    cat > "$MODFILE" <<EOF
blacklist bluetooth
blacklist iwlwifi
install bluetooth /bin/true
install iwlwifi /bin/true
EOF
    echo "✔ Wireless/Bluetooth bloqueados"
else
    echo "ℹ️ Ambiente desktop detectado — pulando wireless"
fi

echo -e "\n[103] Firewall default deny (seguro)"

# Regras mínimas ANTES do DROP
iptables -C INPUT  -i lo -j ACCEPT 2>/dev/null || iptables -A INPUT  -i lo -j ACCEPT
iptables -C OUTPUT -o lo -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o lo -j ACCEPT

iptables -C INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
iptables -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -C OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Preserva SSH se ativo
if ss -tln | awk '{print $4}' | grep -Eq ':(22|2222)$'; then
    iptables -C INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
fi

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

echo "✔ Política default deny aplicada com segurança"

echo -e "\n[104] firewalld — não aplicável ao Debian (audit-only)"

echo -e "\n[105] Regras essenciais já tratadas acima"

echo -e "\n[106] Regras explícitas para portas abertas"

PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | sed 's/.*://g' | sort -u | grep -v '^$')
for P in $PORTS; do
    iptables -C INPUT -p tcp --dport "$P" -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport "$P" -j ACCEPT
done

echo "✔ Portas explícitas liberadas"

echo -e "\n[107] Persistência de firewall"

if dpkg -s netfilter-persistent &>/dev/null; then
    iptables-save > /etc/iptables/rules.v4
    systemctl enable --now netfilter-persistent &>/dev/null
    echo "✔ Regras persistidas"
else
    echo "⚠️ Persistência não instalada (iptables-persistent/netfilter-persistent)"
fi

echo -e "\n[108] TLS mínimo 1.2 — AUDIT ONLY (Debian 12 já conforme)"

echo "✔ Hardening de rede finalizado"
