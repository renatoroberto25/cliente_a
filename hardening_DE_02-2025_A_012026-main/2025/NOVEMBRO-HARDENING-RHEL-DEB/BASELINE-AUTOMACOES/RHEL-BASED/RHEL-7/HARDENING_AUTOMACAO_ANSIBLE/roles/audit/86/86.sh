#!/usr/bin/env bash
echo "[86–98] Verificações de IPv6 e parâmetros de rede"

# 86 - Disable IPv6
echo "[86] Verifique se o IPv6 está desabilitado"
if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -q ' = 1'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

# 87 - Ensure wireless interfaces are disabled
echo "[87] Verifique se interfaces wireless estão desabilitadas"
nmcli dev status 2>/dev/null | grep -iq wifi && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# 88 - Ensure IP forwarding is disabled
echo "[88] Verifique se o IP forwarding está desabilitado"
sysctl net.ipv4.ip_forward 2>/dev/null | grep -q ' = 0' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 89 - Ensure packet redirect sending is disabled
echo "[89] Verifique se o envio de redirects está desabilitado"
sysctl net.ipv4.conf.all.send_redirects 2>/dev/null | grep -q ' = 0' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 90 - Ensure source routed packets are not accepted
echo "[90] Verifique se pacotes source-routed não são aceitos"
sysctl net.ipv4.conf.all.accept_source_route 2>/dev/null | grep -q ' = 0' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 91 - Ensure ICMP redirects are not accepted
echo "[91] Verifique se ICMP redirects não são aceitos"
sysctl net.ipv4.conf.all.accept_redirects 2>/dev/null | grep -q ' = 0' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 92 - Ensure secure ICMP redirects are not accepted
echo "[92] Verifique se secure ICMP redirects não são aceitos"
sysctl net.ipv4.conf.all.secure_redirects 2>/dev/null | grep -q ' = 0' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 93 - Ensure suspicious packets are logged
echo "[93] Verifique se pacotes suspeitos são registrados (log_martians)"
sysctl net.ipv4.conf.all.log_martians 2>/dev/null | grep -q ' = 1' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 94 - Ensure broadcast ICMP requests are ignored
echo "[94] Verifique se requisições ICMP broadcast são ignoradas"
sysctl net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null | grep -q ' = 1' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 95 - Ensure bogus ICMP responses are ignored
echo "[95] Verifique se respostas ICMP falsas são ignoradas"
sysctl net.ipv4.icmp_ignore_bogus_error_responses 2>/dev/null | grep -q ' = 1' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 96 - Ensure Reverse Path Filtering is enabled
echo "[96] Verifique se o Reverse Path Filtering está habilitado"
sysctl net.ipv4.conf.all.rp_filter 2>/dev/null | grep -q ' = 1' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 97 - Ensure TCP SYN Cookies is enabled
echo "[97] Verifique se o TCP SYN Cookies está habilitado"
sysctl net.ipv4.tcp_syncookies 2>/dev/null | grep -q ' = 1' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 98 - Ensure IPv6 router advertisements are not accepted
echo "[98] Verifique se anúncios de roteadores IPv6 não são aceitos"
sysctl net.ipv6.conf.all.accept_ra 2>/dev/null | grep -q ' = 0' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"