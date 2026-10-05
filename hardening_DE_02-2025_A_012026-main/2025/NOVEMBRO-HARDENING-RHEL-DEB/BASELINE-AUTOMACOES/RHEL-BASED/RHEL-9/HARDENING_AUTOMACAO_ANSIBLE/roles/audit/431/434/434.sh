#!/usr/bin/env bash
echo -e "\n[142] Certifique-se de que o tráfego de loopback do nftables esteja configurado"

{
   l_output="" l_output2="" l_fw=""

   if systemctl is-enabled firewalld.service 2>/dev/null | grep -q 'enabled'; then
      echo "ℹ️ FirewallD está em uso – recomendação não aplicável."
      l_fw="fwd"
   elif systemctl is-enabled nftables.service 2>/dev/null | grep -q 'enabled'; then
      l_fw="nft"
   else
      echo "⚠️ [REPROVADO]: Nenhum firewall habilitado. Configure Firewalld ou NFTables."
      exit 0
   fi

   if [ "$l_fw" = "nft" ]; then
      ruleset="$(nft list ruleset)"

      # Verifica aceitação explícita da interface lo
      if awk '/hook input/,/}/' <<< "$ruleset" | grep -Pq '\b"lo"\b.*accept'; then
         l_output+="✅ Tráfego para interface loopback (lo) aceito"
      else
         l_output2+="⚠️ Tráfego para interface loopback (lo) não está aceito"
      fi

      # Verifica DROP explícito para pacotes IPv4 de loopback falsificados
      if grep -Pq 'ip\s+saddr\s+127\.0\.0\.0/8.*drop' <<< "$ruleset" || grep -Pq 'ip\s+daddr\s+!=\s+127\.0\.0\.1\s+ip\s+saddr\s+127\.0\.0\.1\s+drop' <<< "$ruleset"; then
         l_output+="\n✅ Tráfego IPv4 falsificado de loopback é descartado"
      else
         l_output2+="\n⚠️ Tráfego IPv4 falsificado de loopback NÃO está sendo descartado"
      fi

      # Verifica DROP explícito para pacotes IPv6 de loopback falsificados, se IPv6 ativo
      if grep -Pq '^0$' /sys/module/ipv6/parameters/disable 2>/dev/null; then
         if grep -Pq 'ip6\s+saddr\s+::1.*drop' <<< "$ruleset" || grep -Pq 'ip6\s+daddr\s+!=\s+::1\s+ip6\s+saddr\s+::1\s+drop' <<< "$ruleset"; then
            l_output+="\n✅ Tráfego IPv6 falsificado de loopback é descartado"
         else
            l_output2+="\n⚠️ Tráfego IPv6 falsificado de loopback NÃO está sendo descartado"
         fi
      fi
   fi

   if [ "$l_fw" = "fwd" ] || [ -z "$l_output2" ]; then
      echo -e "\n✅ [APROVADO]: Todas as verificações passaram."
      [ -n "$l_output" ] && echo -e "$l_output"
   else
      echo -e "\n[⚠️[REPROVADO]]: Inconsistências encontradas:\n$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas detectadas:\n$l_output"
   fi
}
exit 0