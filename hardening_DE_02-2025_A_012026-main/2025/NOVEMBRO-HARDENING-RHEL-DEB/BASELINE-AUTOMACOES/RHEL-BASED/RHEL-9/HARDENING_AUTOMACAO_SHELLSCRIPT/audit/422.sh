#!/usr/bin/env bash
echo -e "\n[138] Certifique-se de que o tráfego loopback no firewalld esteja corretamente configurado"

{
   l_output="" l_output2="" l_hbfw=""

   if systemctl is-enabled firewalld.service | grep -q 'enabled'; then
      echo "- FirewallD detectado como ativo"
      l_hbfw="fwd"
   elif systemctl is-enabled nftables.service 2>/dev/null | grep -q 'enabled'; then
      echo "- nftables está em uso. Controle não se aplica (NA)."
      l_hbfw="nft"
   else
      echo "⚠️[REPROVADO]: Nenhum firewall ativo detectado (Firewalld ou nftables)."
      exit 0
   fi

   if [ "$l_hbfw" = "fwd" ]; then
      if nft list ruleset | awk '/hook\s+input\s+/,/\}\s*(#.*)?$/' | grep -Pq -- '\H+\h+"lo"\h+accept'; then
         l_output+="\n✅ Interface de loopback está aceita corretamente"
      else
         l_output2+="\n❗ Tráfego para interface de loopback não está aceito"
      fi

      l_ipsaddr="$(nft list ruleset | awk '/filter_IN_public_deny|hook\s+input\s+/,/\}\s*(#.*)?$/' | grep -P -- 'ip\h+saddr')"
      if grep -Pq -- 'ip\h+saddr\h+127\.0\.0\.0\/8\h+(counter\h+packets\h+\d+\h+bytes\h+\d+\h+)?drop' <<< "$l_ipsaddr" || grep -Pq -- 'ip\h+daddr\h+\!\=\h+127\.0\.0\.1\h+ip\h+saddr\h+127\.0\.0\.1\h+drop' <<< "$l_ipsaddr"; then
         l_output+="\n✅ Tráfego IPv4 de loopback incorreto está bloqueado"
      else
         l_output2+="\n❗ Tráfego IPv4 de loopback incorreto não está bloqueado"
      fi

      if grep -Pq -- '^\h*0\h*$' /sys/module/ipv6/parameters/disable; then
         l_ip6saddr="$(nft list ruleset | awk '/filter_IN_public_deny|hook input/,/}/' | grep 'ip6 saddr')"
         if grep -Pq 'ip6\h+saddr\h+::1\h+(counter\h+packets\h+\d+\h+bytes\h+\d+\h+)?drop' <<< "$l_ip6saddr" || grep -Pq -- 'ip6\h+daddr\h+\!=\h+::1\h+ip6\h+saddr\h+::1\h+drop' <<< "$l_ip6saddr"; then
            l_output+="\n✅ Tráfego IPv6 de loopback incorreto está bloqueado"
         else
            l_output2+="\n❗ Tráfego IPv6 de loopback incorreto não está bloqueado"
         fi
      fi
   fi

   if [ "$l_hbfw" = "nft" ]; then
      exit 0
   elif [ -z "$l_output2" ]; then
      echo -e "$l_output"
      echo -e "\n✅ [APROVADO]"
   else
      echo -e "$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas detectadas:$l_output"
      echo -e "\n⚠️[REPROVADO]"
   fi
}