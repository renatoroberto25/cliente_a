#!/usr/bin/env bash
echo "[86–98] IPv6 e parâmetros de rede"

# 86 - Disable IPv6
echo "[86] Verifique se o IPv6 está desabilitado"
if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -q ' = 1'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Edite /etc/sysctl.conf e adicione: net.ipv6.conf.all.disable_ipv6 = 1"
fi

# 87 - Wireless interfaces
echo "[87] Verifique se interfaces wireless estão desabilitadas"
if nmcli dev status 2>/dev/null | grep -iq wifi; then
  echo "⚠️ REPROVADO - Desative Wi-Fi via nmcli ou remova o driver no /etc/modprobe.d/"
else
  echo "✅ APROVADO"
fi

# 88 - IP forwarding
echo "[88] Verifique se o IP forwarding está desabilitado"
if sysctl net.ipv4.ip_forward 2>/dev/null | grep -q ' = 0'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Defina net.ipv4.ip_forward = 0 em /etc/sysctl.conf"
fi

# 89 - Packet redirect sending
echo "[89] Verifique se o envio de redirects está desabilitado"
if sysctl net.ipv4.conf.all.send_redirects 2>/dev/null | grep -q ' = 0'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Ajuste net.ipv4.conf.all.send_redirects = 0 em /etc/sysctl.conf"
fi

# 90 - Source routed packets
echo "[90] Verifique se pacotes source-routed não são aceitos"
if sysctl net.ipv4.conf.all.accept_source_route 2>/dev/null | grep -q ' = 0'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Defina net.ipv4.conf.all.accept_source_route = 0 em /etc/sysctl.conf"
fi

# 91 - ICMP redirects
echo "[91] Verifique se ICMP redirects não são aceitos"
if sysctl net.ipv4.conf.all.accept_redirects 2>/dev/null | grep -q ' = 0'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Configure net.ipv4.conf.all.accept_redirects = 0 em /etc/sysctl.conf"
fi

# 92 - Secure ICMP redirects
echo "[92] Verifique se secure ICMP redirects não são aceitos"
if sysctl net.ipv4.conf.all.secure_redirects 2>/dev/null | grep -q ' = 0'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Configure net.ipv4.conf.all.secure_redirects = 0 em /etc/sysctl.conf"
fi

# 93 - Suspicious packets log
echo "[93] Verifique se pacotes suspeitos são registrados"
if sysctl net.ipv4.conf.all.log_martians 2>/dev/null | grep -q ' = 1'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Adicione net.ipv4.conf.all.log_martians = 1 em /etc/sysctl.conf"
fi

# 94 - Broadcast ICMP requests
echo "[94] Verifique se requisições ICMP broadcast são ignoradas"
if sysctl net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null | grep -q ' = 1'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Configure net.ipv4.icmp_echo_ignore_broadcasts = 1 em /etc/sysctl.conf"
fi

# 95 - Bogus ICMP responses
echo "[95] Verifique se respostas ICMP falsas são ignoradas"
if sysctl net.ipv4.icmp_ignore_bogus_error_responses 2>/dev/null | grep -q ' = 1'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Configure net.ipv4.icmp_ignore_bogus_error_responses = 1 em /etc/sysctl.conf"
fi

# 96 - Reverse Path Filtering
echo "[96] Verifique se o Reverse Path Filtering está habilitado"
if sysctl net.ipv4.conf.all.rp_filter 2>/dev/null | grep -q ' = 1'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Adicione net.ipv4.conf.all.rp_filter = 1 em /etc/sysctl.conf"
fi

# 97 - TCP SYN Cookies
echo "[97] Verifique se o TCP SYN Cookies está habilitado"
if sysctl net.ipv4.tcp_syncookies 2>/dev/null | grep -q ' = 1'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Adicione net.ipv4.tcp_syncookies = 1 em /etc/sysctl.conf"
fi

# 98 - IPv6 router advertisements
echo "[98] Verifique se anúncios de roteadores IPv6 não são aceitos"
if sysctl net.ipv6.conf.all.accept_ra 2>/dev/null | grep -q ' = 0'; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Ajuste net.ipv6.conf.all.accept_ra = 0 em /etc/sysctl.conf"
fi