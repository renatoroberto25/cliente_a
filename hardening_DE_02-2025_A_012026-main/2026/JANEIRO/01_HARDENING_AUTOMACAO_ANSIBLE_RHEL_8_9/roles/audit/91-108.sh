#!/usr/bin/env bash

echo -e "\n[91] IP forwarding desabilitado"
(sysctl -n net.ipv4.ip_forward 2>/dev/null | grep -q '^0$' && sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[92] Redirecionamentos de pacotes desabilitados"
(sysctl -n net.ipv4.conf.all.send_redirects 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[93] Source-routed packets bloqueados"
(sysctl -n net.ipv4.conf.all.accept_source_route 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[94] ICMP redirects bloqueados"
(sysctl -n net.ipv4.conf.all.accept_redirects 2>/dev/null | grep -q '^0$' && sysctl -n net.ipv4.conf.all.secure_redirects 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[95] Reverse path filtering habilitado"
(sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null | grep -Eq '^[12]$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[96] ICMP broadcast ignorado"
(sysctl -n net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[97] Respostas ICMP inválidas ignoradas"
(sysctl -n net.ipv4.icmp_ignore_bogus_error_responses 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[98] TCP SYN cookies habilitados"
(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[99] IPv6 desabilitado ou endurecido"
(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[100] ICMP timestamp-request drop"
(firewall-cmd --direct --query-rule ipv4 filter INPUT 0 -p icmp --icmp-type timestamp-request -j DROP &>/dev/null || nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-request[[:space:]]+drop' || iptables -L INPUT -n 2>/dev/null | grep -qi 'icmp type timestamp-request.*DROP') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[101] ICMP timestamp-reply drop"
(iptables -L INPUT -v -n | grep -q 'icmp type timestamp-reply.*DROP' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[101-1] ICMP timestamp-reply drop"
( firewall-cmd --direct --query-rule ipv4 filter INPUT 0 -p icmp --icmp-type timestamp-reply -j DROP 2>/dev/null || nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-reply[[:space:]]+drop' || iptables -L INPUT -n 2>/dev/null | grep -qi 'icmp type timestamp-reply.*DROP' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[102] Wireless/Bluetooth desabilitados"
(lsmod | grep -Eq 'bluetooth|iwlwifi' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[103] Firewall com política default deny"
(iptables -L INPUT   -n 2>/dev/null | grep -q "policy DROP" && iptables -L FORWARD -n 2>/dev/null | grep -q "policy DROP" && iptables -L OUTPUT  -n 2>/dev/null | grep -q "policy DROP") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[104] Apenas uma solução de firewall ativa"
( [ "$(printf "%s\n" "$(systemctl is-active firewalld >/dev/null 2>&1 && echo F)" "$(iptables -L >/dev/null 2>&1 && echo F)" "$(ip6tables -L >/dev/null 2>&1 && echo F)" | grep -c F)" -eq 1 ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO" )

echo -e "\n[105] Regras básicas de firewall"
(iptables -L INPUT -n 2>/dev/null | grep -q "lo .* ACCEPT" && iptables -L INPUT -n | grep -Eq "ESTABLISHED|RELATED" && iptables -L OUTPUT -n | grep -q "ACCEPT") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[106] Regras explícitas para portas abertas"
(ss -tuln | awk 'NR>1 {print $5}' | sed 's/.*://g' | sort -u | grep -v '^$' | while read P; do iptables -L INPUT -n 2>/dev/null | grep -q ":${P} " || exit 1; done && exit 0) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[107] Regras de firewall persistentes"
(iptables-save 2>/dev/null | grep -q ".") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[108] TLS mínimo 1.2/1.3"
(grep -Eq "(TLSv1\.2|TLSv1\.3)" /etc/crypto-policies/config 2>/dev/null || grep -Eq "(MinProtocol.*TLSv1\.2|ssl_protocol.*TLSv1\.2)" /etc/httpd/conf.d/* 2>/dev/null || grep -Eq "(ssl_protocol.*TLSv1\.2)" /etc/nginx/* 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

