#!/usr/bin/env bash

{
   l_output="" l_output2=""
   a_parlist=("kernel.yama.ptrace_scope=1")
   l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"

   kernel_parameter_chk()
   {
      l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)"

      if [ "$l_krp" = "$l_kpvalue" ]; then
         l_output+="➡️ Parâmetro: $l_kpname\n"
         l_output+="✅ Execução atual correta: \"$l_krp\".\n"
      else
         l_output2+="➡️ Parâmetro: $l_kpname\n"
         l_output2+="❗ Valor em execução: \"$l_krp\" — esperado: \"$l_kpvalue\".\n"
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
            l_fkpname="${l_fkpname// /}"
            l_fkpvalue="${l_fkpvalue// /}"
            l_file="${A_out[$l_kpname]}"

            if [ "$l_fkpvalue" = "$l_kpvalue" ]; then
               l_output+="✅ Persistente correto: \"$l_fkpvalue\" em: $l_file\n"
            else
               l_output2+="❗ Persistente incorreto: \"$l_fkpvalue\" em: $l_file — esperado: \"$l_kpvalue\".\n"
            fi
         done < <(grep -Po -- "^\h*$l_kpname\h*=\h*\H+" "${A_out[@]}")
      else
         l_output2+="❗ Parâmetro \"$l_kpname\" não encontrado em arquivos persistentes reconhecidos.\n"
      fi
   }

   while IFS="=" read -r l_kpname l_kpvalue; do
      l_kpname="${l_kpname// /}"
      l_kpvalue="${l_kpvalue// /}"

      if ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable && grep -q '^net.ipv6.' <<< "$l_kpname"; then
         l_output+="➡️ Parâmetro: $l_kpname\n✅ IPv6 desativado — parâmetro não aplicável.\n"
      else
         kernel_parameter_chk
      fi
   done < <(printf '%s\n' "${a_parlist[@]}")

   if [ -z "$l_output2" ]; then
      echo -e "\n✅ Resultado da Auditoria: Parâmetro(s) corretamente configurado(s).\n"
      echo -e "$l_output"
   else
      echo -e "\n⚠️ Resultado da Auditoria: Foram encontradas inconsistências.\n"
      echo -e "$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas detectadas:\n" && echo -e "$l_output"
   fi
}

exit 0
