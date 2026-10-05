#!/usr/bin/env bash

echo " [146 - 151] Verificar parâmetros de configuração do SSH"

# Ciphers
if sshd -T | grep -Pi -- '^ciphers\s+"?([^#\n\r]+,)?((3des|blowfish|cast128|aes(128|192|256))-cbc|arcfour(128|256)?|rijndael-cbc@lysator\.liu\.se|chacha20-poly1305@openssh\.com)\b' &>/dev/null; then
  echo "⚠️ [REPROVADO] Ciphers fracos ou chacha20-poly1305@openssh.com encontrados. Verifique CVE-2023-48795"
else
  echo "✅ [APROVADO] Nenhum cipher fraco encontrado"
fi

# KexAlgorithms
if sshd -T | grep -Pi -- 'kexalgorithms\s+([^#\n\r]+,)?(diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1)\b' &>/dev/null; then
  echo "⚠️ [REPROVADO] Algoritmo de troca de chaves fraco encontrado"
else
  echo "✅ [APROVADO] Nenhum algoritmo de troca de chaves fraco encontrado"
fi

# MACs
if sshd -T | grep -Pi -- 'macs\s+([^#\n\r]+,)?(hmac-md5|hmac-md5-96|hmac-ripemd160|hmac-sha1-96|umac-64@openssh\.com|hmac-md5-etm@openssh\.com|hmac-md5-96-etm@openssh\.com|hmac-ripemd160-etm@openssh\.com|hmac-sha1-96-etm@openssh\.com|umac-64-etm@openssh\.com|umac-128-etm@openssh\.com)\b' &>/dev/null; then
  echo "⚠️ [REPROVADO] MACs fracos encontrados"
else
  echo "✅ [APROVADO] Nenhum MAC fraco encontrado"
fi

# AllowUsers, AllowGroups, DenyUsers, DenyGroups
if sshd -T | grep -Pi -- '^\s*(allow|deny)(users|groups)\s+\S+' &>/dev/null; then
  echo "✅ [APROVADO] Parâmetros de controle de acesso por usuário ou grupo estão definidos"
else
  echo "⚠️ [REPROVADO] Nenhum parâmetro AllowUsers, AllowGroups, DenyUsers ou DenyGroups configurado"
fi

# Banner
if sshd -T | grep -Pi -- '^banner\s+\/\S+' &>/dev/null; then
  echo "✅ [APROVADO] Banner configurado corretamente"
else
  echo "⚠️ [REPROVADO] Nenhum banner configurado"
fi

# ClientAliveInterval e ClientAliveCountMax
client_alive_interval=$(sshd -T | awk '/clientaliveinterval/ {print $2}')
client_alive_count_max=$(sshd -T | awk '/clientalivecountmax/ {print $2}')
max_interval=15
max_count=3
erro=0

[[ -z "$client_alive_interval" || "$client_alive_interval" -gt "$max_interval" ]] && {
  echo "⚠️ [REPROVADO] ClientAliveInterval acima de $max_interval"
  erro=1
}

[[ -z "$client_alive_count_max" || "$client_alive_count_max" -gt "$max_count" ]] && {
  echo "⚠️ [REPROVADO] ClientAliveCountMax acima de $max_count"
  erro=1
}

[ "$erro" -eq 0 ] && echo "✅ [APROVADO] Parâmetros ClientAlive configurados corretamente"

echo -e "\n✅ Auditoria finalizada"
exit 0