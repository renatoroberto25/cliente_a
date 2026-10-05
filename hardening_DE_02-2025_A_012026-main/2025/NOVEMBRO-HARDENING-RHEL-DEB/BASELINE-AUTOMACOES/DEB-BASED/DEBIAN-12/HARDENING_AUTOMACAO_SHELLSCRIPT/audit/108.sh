#!/usr/bin/env bash
# audit_network_and_modules.sh
# Auditoria: controles aplicáveis 108-125

echo -e "\n[108] Verifique se o IPv6 está desabilitado"
sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -q '^1$' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[109] Verifique se interfaces wireless estão desabilitadas (rfkill / net)"
if command -v rfkill >/dev/null 2>&1; then
  if rfkill list all 2>/dev/null | grep -Eiq 'wlan|wifi'; then
    echo "⚠️ REPROVADO"
  else
    echo "✅ APROVADO"
  fi
else
  if ip link show | grep -Eiq 'wlan|wl'; then
    echo "⚠️ REPROVADO (interfaces wireless detectadas)"
  else
    echo "✅ APROVADO"
  fi
fi

echo -e "\n[110] Verifique se serviços Bluetooth não estão em uso"
if systemctl list-unit-files 2>/dev/null | grep -q '^bluetooth.service'; then
  ( ! systemctl is-active --quiet bluetooth.service && ! systemctl is-enabled --quiet bluetooth.service ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

echo -e "\n[111] Verifique se o módulo do kernel dccp não está disponível"
if lsmod | grep -q '^dccp\b'; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

echo -e "\n[112] Verifique se o módulo do kernel tipc não está disponível"
if lsmod | grep -q '^tipc\b'; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

echo -e "\n[113] Verifique se o módulo do kernel rds não está disponível"
if lsmod | grep -q '^rds\b'; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

echo -e "\n[114] Verifique se o módulo do kernel sctp não está disponível"
if lsmod | grep -q '^sctp\b'; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

echo -e "\n[115] Verifique se o encaminhamento de IP está desabilitado"
sysctl -n net.ipv4.ip_forward 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[116] Verifique se envio de redirects está desabilitado"
sysctl -n net.ipv4.conf.all.send_redirects 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[117] Verifique se respostas ICMP inválidas são ignoradas"
sysctl -n net.ipv4.icmp_ignore_bogus_error_responses 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[118] Verifique se broadcast ICMP requests são ignorados"
sysctl -n net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[119] Verifique se ICMP redirects não são aceitos"
sysctl -n net.ipv4.conf.all.accept_redirects 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[120] Verifique se secure ICMP redirects não são aceitos"
sysctl -n net.ipv4.conf.all.secure_redirects 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[121] Verifique se reverse path filtering está habilitado"
sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null | grep -Eq '^[12]$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[122] Verifique se source routed packets não são aceitos"
sysctl -n net.ipv4.conf.all.accept_source_route 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[123] Verifique se pacotes suspeitos são logados"
sysctl -n net.ipv4.conf.all.log_martians 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[124] Verifique se TCP SYN cookies estão habilitados"
sysctl -n net.ipv4.tcp_syncookies 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[125] Verifique se IPv6 Router Advertisements não são aceitos"
sysctl -n net.ipv6.conf.all.accept_ra 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[PLUS] Auditoria de timestamp-request"
if command -v nft >/dev/null; then
    nft list ruleset | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-request[[:space:]]+drop' && \
        echo "✅ APROVADO (nft ativo)" || echo "⚠️ REPROVADO (nft ativo, sem regra)"
elif [ -f /etc/nftables.conf ]; then
    grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-request[[:space:]]+drop' /etc/nftables.conf && \
        echo "✅ APROVADO (regra presente no .conf)" || echo "⚠️ REPROVADO (sem regra no .conf)"
else
    echo "❌ Nenhum firewall disponível — não há regra para ICMP timestamp-request."
fi

echo -e "\n[PLUS] Auditoria de timestamp-reply"
if command -v nft >/dev/null; then
    nft list ruleset | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-reply[[:space:]]+drop' && \
        echo "✅ APROVADO (nft ativo)" || echo "⚠️ REPROVADO (nft ativo, sem regra)"
elif [ -f /etc/nftables.conf ]; then
    grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-reply[[:space:]]+drop' /etc/nftables.conf && \
        echo "✅ APROVADO (regra presente no .conf)" || echo "⚠️ REPROVADO (sem regra no .conf)"
else
    echo "❌ Nenhum firewall disponível — não há regra para ICMP timestamp-reply."
fi