#!/usr/bin/env bash

{
   echo "124 Ensure IP forwarding is disabled"

   l_output="" l_output2="" l_ipv6_disabled=""
   a_parlist=("net.ipv4.ip_forward=0" "net.ipv6.conf.all.forwarding=0")
   l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"

   f_ipv6_chk() {
      l_ipv6_disabled=""
      ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable && l_ipv6_disabled="yes"
      if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
         sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
         l_ipv6_disabled="yes"
      fi
      [ -z "$l_ipv6_disabled" ] && l_ipv6_disabled="no"
   }

   f_kernel_parameter_chk() {
      l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)"
      if [ "$l_krp" = "$l_kpvalue" ]; then
         l_output+="\n - \"$l_kpname\" ✅ [APROVADO]: Corretamente configurado para \"$l_krp\" (execução)"
      else
         l_output2+="\n - \"$l_kpname\" ⚠️[REPROVADO]: Configurado como \"$l_krp\", esperado: \"$l_kpvalue\" (execução)"
      fi

      unset A_out; declare -A A_out
      while read -r l_out; do
         if [ -n "$l_out" ]; then
            if [[ $l_out =~ ^\s*# ]]; then
               l_file="${l_out//# /}"
            else
               l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
               [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_file")
            fi
         fi
      done < <(/usr/lib/systemd/systemd-sysctl --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

      if [ -n "$l_ufwscf" ]; then
         l_kpar="$(grep -Po "^\h*$l_kpname\b" "$l_ufwscf" | xargs)"
         l_kpar="${l_kpar//\//.}"
         [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
      fi

      if (( ${#A_out[@]} > 0 )); then
         while IFS="=" read -r l_fkpname l_fkpvalue; do
            l_fkpname="${l_fkpname// /}"; l_fkpvalue="${l_fkpvalue// /}"
            if [ "$l_fkpvalue" = "$l_kpvalue" ]; then
               l_output+="\n - \"$l_kpname\" ✅ [APROVADO]: Persistente em \"$(printf '%s' "${A_out[@]}")\" com valor \"$l_fkpvalue\""
            else
               l_output2+="\n - \"$l_kpname\" ⚠️[REPROVADO]: Valor persistente \"$l_fkpvalue\" em \"$(printf '%s' "${A_out[@]}")\", esperado: \"$l_kpvalue\""
            fi
         done < <(grep -Po -- "^\h*$l_kpname\h*=\h*\H+" "${A_out[@]}")
      else
         l_output2+="\n - \"$l_kpname\" ⚠️[REPROVADO]: Não está configurado em arquivos persistentes reconhecidos."
      fi
   }

   while IFS="=" read -r l_kpname l_kpvalue; do
      l_kpname="${l_kpname// /}"; l_kpvalue="${l_kpvalue// /}"
      if grep -q '^net.ipv6.' <<< "$l_kpname"; then
         [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
         if [ "$l_ipv6_disabled" = "yes" ]; then
            l_output+="\n - IPv6 está desativado, \"$l_kpname\" não é aplicável."
         else
            f_kernel_parameter_chk
         fi
      else
         f_kernel_parameter_chk
      fi
   done < <(printf '%s\n' "${a_parlist[@]}")

   unset a_parlist A_out

   if [ -z "$l_output2" ]; then
      echo -e "\n- Resultado da Auditoria (124):\n$l_output\n"
   else
      echo -e "\n- Resultado da Auditoria (124):\n$l_output2"
      [ -n "$l_output" ] && echo -e "\n- Configurações corretas:\n$l_output\n"
   fi

   exit 0
}
