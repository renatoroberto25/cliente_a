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

echo "[ICMP 100-101] Remediação genérica: timestamp-request e timestamp-reply (DROP)"

# ---------------------------------------------------------
# Função genérica: tenta aplicar no firewalld → nft → iptables
# sem nunca falhar, sem parar o script, e garantindo que
# PELO MENOS UMA implementação seja aplicada se existir.
# ---------------------------------------------------------
apply_rule() {
    local TYPE="$1"

    # 1) FIREWALLD
    if systemctl is-active firewalld &>/dev/null; then
        echo "→ firewalld detectado — tentando aplicar via firewall-cmd ($TYPE)"
        firewall-cmd --direct --query-rule ipv4 filter INPUT 0 -p icmp --icmp-type "$TYPE" -j DROP &>/dev/null || \
        firewall-cmd --direct --add-rule   ipv4 filter INPUT 0 -p icmp --icmp-type "$TYPE" -j DROP &>/dev/null
        firewall-cmd --runtime-to-permanent &>/dev/null
        if firewall-cmd --direct --query-rule ipv4 filter INPUT 0 -p icmp --icmp-type "$TYPE" -j DROP &>/dev/null; then
            echo "✔ Aplicado via firewalld: $TYPE"
            return 0
        else
            echo "⚠️ Falha no firewalld para $TYPE — tentando próximo backend"
        fi
    fi

    # 2) NFTABLES
    if command -v nft >/dev/null && nft list ruleset 2>/dev/null | grep -q 'table inet'; then
        echo "→ nftables detectado — tentando aplicar ($TYPE)"
        nft list ruleset | grep -Ei "icmp type $TYPE.*drop" &>/dev/null || \
            nft add rule inet filter input icmp type "$TYPE" drop &>/dev/null
        nft list ruleset | grep -Ei "icmp type $TYPE.*drop" &>/dev/null
        if [ $? -eq 0 ]; then
            echo "✔ Aplicado via nftables: $TYPE"
            return 0
        else
            echo "⚠️ Falha no nft para $TYPE — tentando iptables"
        fi
    fi

    # 3) IPTABLES
    if command -v iptables >/dev/null; then
        echo "→ iptables detectado — tentando aplicar ($TYPE)"
        iptables -C INPUT -p icmp --icmp-type "$TYPE" -j DROP 2>/dev/null || \
            iptables -A INPUT -p icmp --icmp-type "$TYPE" -j DROP &>/dev/null
        iptables -C INPUT -p icmp --icmp-type "$TYPE" -j DROP &>/dev/null
        if [ $? -eq 0 ]; then
            echo "✔ Aplicado via iptables: $TYPE"
            return 0
        else
            echo "⚠️ Falha no iptables para $TYPE"
        fi
    fi

    # 4) ULTIMA FALHA
    echo "❗ Nenhum backend conseguiu aplicar regra para $TYPE"
    return 1
}

# ---------------------------------------------------------
# Aplicar para ambas as regras (request + reply)
# ---------------------------------------------------------
apply_rule "timestamp-request"
apply_rule "timestamp-reply"
echo "✔ ICMP timestamp requests e replies bloqueados"

echo -e "\n[102] Desabilitar módulos Wireless/Bluetooth"

for m in bluetooth iwlwifi; do
    if lsmod | grep -q "^$m"; then
        modprobe -r "$m" 2>/dev/null && echo "✔ removido: $m"
    fi
done

MODFILE="/etc/modprobe.d/hardening-wireless.conf"
backup "$MODFILE"

echo "blacklist bluetooth" > "$MODFILE"
echo "blacklist iwlwifi"  >> "$MODFILE"

echo "install bluetooth /bin/true" >> "$MODFILE"
echo "install iwlwifi /bin/true"  >> "$MODFILE"

echo "✔ Wireless/Bluetooth bloqueados por blacklist"

echo -e "\n[103] Configurar política default deny"

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

echo "✔ Política padrão definida como DROP"

echo -e "\n[104] Garantir apenas uma solução de firewall"

systemctl stop firewalld 2>/dev/null
systemctl disable firewalld 2>/dev/null
systemctl mask firewalld 2>/dev/null

echo "✔ firewalld desabilitado (iptables em uso)"

echo -e "\n[105] Regras básicas essenciais"

iptables -C INPUT -i lo -j ACCEPT 2>/dev/null || iptables -A INPUT -i lo -j ACCEPT
iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
         iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -C OUTPUT -j ACCEPT 2>/dev/null || iptables -A OUTPUT -j ACCEPT

echo "✔ Regras essenciais aplicadas"

echo -e "\n[106] Criar regras explícitas para portas abertas"

PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | sed 's/.*://g' | sort -u | grep -v '^$')

for P in $PORTS; do
    iptables -C INPUT -p tcp --dport "$P" -j ACCEPT 2>/dev/null || \
        iptables -A INPUT -p tcp --dport "$P" -j ACCEPT
done

echo "✔ Regras explícitas criadas para todas as portas escutando"

echo -e "\n[107] Garantir que regras são persistentes"

iptables-save > /etc/iptables/rules.v4 2>/dev/null
echo "✔ Regras salvas em /etc/iptables/rules.v4"

echo -e "\n[108] Forçar mínimo TLS 1.2"
if command -v update-crypto-policies &>/dev/null; then
    CURRENT="$(update-crypto-policies --show 2>/dev/null)"

    if [ "$CURRENT" != "DEFAULT" ] && [ "$CURRENT" != "FUTURE" ]; then
        update-crypto-policies --set DEFAULT
    fi
fi

echo -e "\n[108-1] Forçar mínimo TLS 1.2 APACHE HTTPD"
# Apache - TLS mínimo 1.2
if [ -d /etc/httpd ]; then
    grep -Rqs '^\s*SSLProtocol' /etc/httpd && \
    sed -ri 's/^\s*SSLProtocol.*/SSLProtocol -all +TLSv1.2 +TLSv1.3/' /etc/httpd/conf.d/*.conf 2>/dev/null
fi

echo -e "\n[108-2] Forçar mínimo TLS 1.2 NGINX"
# Nginx - TLS mínimo 1.2
if [ -d /etc/nginx ]; then
    grep -Rqs '^\s*ssl_protocols' /etc/nginx && \
    sed -ri 's/^\s*ssl_protocols.*/ssl_protocols TLSv1.2 TLSv1.3;/' /etc/nginx/nginx.conf /etc/nginx/conf.d/*.conf 2>/dev/null
fi

echo "✔ TLS mínimo configurado para 1.2/1.3"
