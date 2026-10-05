#!/usr/bin/env bash

{
   l_output="" l_output2=""
   a_parlist=("Storage=none")
   l_systemd_config_file="/etc/systemd/coredump.conf"

   config_file_parameter_chk()
   {
      unset A_out; declare -A A_out

      while read -r l_out; do
         if [ -n "$l_out" ]; then
            if [[ $l_out =~ ^\s*# ]]; then
               l_file="${l_out//# /}"
            else
               l_systemd_parameter="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
               grep -Piq -- "^\h*$l_systemd_parameter_name\b" <<< "$l_systemd_parameter" && A_out+=(["$l_systemd_parameter"]="$l_file")
            fi
         fi
      done < <(/usr/bin/systemd-analyze cat-config "$l_systemd_config_file" | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

      if (( ${#A_out[@]} > 0 )); then
         while IFS="=" read -r l_systemd_file_parameter_name l_systemd_file_parameter_value; do
            l_systemd_file_parameter_name="${l_systemd_file_parameter_name// /}"
            l_systemd_file_parameter_value="${l_systemd_file_parameter_value// /}"
            l_file="${A_out[$l_systemd_parameter_name]}"

            if grep -Piq "^\h*$l_systemd_parameter_value\b" <<< "$l_systemd_file_parameter_value"; then
               l_output+="➡️ Parâmetro: $l_systemd_parameter_name\n"
               l_output+="✅ Valor correto: \"$l_systemd_file_parameter_value\" em: $l_file\n"
            else
               l_output2+="➡️ Parâmetro: $l_systemd_parameter_name\n"
               l_output2+="❗ Valor incorreto: \"$l_systemd_file_parameter_value\" em: $l_file — esperado: \"$l_systemd_parameter_value\"\n"
            fi
         done < <(grep -Pio -- "^\h*$l_systemd_parameter_name\h*=\h*\H+" "${A_out[@]}")
      else
         l_output2+="➡️ Parâmetro: $l_systemd_parameter_name\n"
         l_output2+="❗ Não encontrado em arquivos de configuração reconhecidos pelo systemd\n"
      fi
   }

   while IFS="=" read -r l_systemd_parameter_name l_systemd_parameter_value; do
      l_systemd_parameter_name="${l_systemd_parameter_name// /}"
      l_systemd_parameter_value="${l_systemd_parameter_value// /}"
      config_file_parameter_chk
   done < <(printf '%s\n' "${a_parlist[@]}")

   if [ -z "$l_output2" ]; then
      echo -e "\n✅ Resultado da Auditoria: Parâmetro corretamente configurado."
      echo -e "$l_output"
   else
      echo -e "\n⚠️ Resultado da Auditoria: Foram encontradas inconsistências."
      echo -e "$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas detectadas:\n" && echo -e "$l_output"
   fi
}

exit 0
