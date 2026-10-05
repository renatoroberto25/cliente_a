#!/usr/bin/env bash
echo "[71]	Garanta que a tela do GDM seja bloqueada quando o usuário estiver ocioso"
{
   l_pkgoutput=""
   if command -v dpkg-query > /dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm > /dev/null 2>&1; then
      l_pq="rpm -q"
   fi

   l_pcl="gdm gdm3"
   for l_pn in $l_pcl; do
      $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Pacote: \"$l_pn\" está instalado\n - Verificando configuração..."
   done

   if [ -n "$l_pkgoutput" ]; then
      l_output="" l_output2=""
      l_idmv="900"
      l_ldmv="5"

      l_kfile="$(grep -Psril '^\h*idle-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/)"
      if [ -n "$l_kfile" ]; then
         l_profile="$(awk -F'/' '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")"
         l_pdbdir="/etc/dconf/db/$l_profile.d"

         l_idv="$(awk -F 'uint32' '/idle-delay/{print $2}' "$l_kfile" | xargs)"
         if [ -n "$l_idv" ]; then
            [ "$l_idv" -gt "0" -a "$l_idv" -le "$l_idmv" ] && l_output="$l_output\n - Parâmetro \"idle-delay\" configurado para $l_idv segundos em \"$l_kfile\""
            [ "$l_idv" = "0" ] && l_output2="$l_output2\n - Parâmetro \"idle-delay\" está desativado (valor 0) em \"$l_kfile\""
            [ "$l_idv" -gt "$l_idmv" ] && l_output2="$l_output2\n - Parâmetro \"idle-delay\" com valor alto ($l_idv > $l_idmv) em \"$l_kfile\""
         else
            l_output2="$l_output2\n - Parâmetro \"idle-delay\" não configurado em \"$l_kfile\""
         fi

         l_ldv="$(awk -F 'uint32' '/lock-delay/{print $2}' "$l_kfile" | xargs)"
         if [ -n "$l_ldv" ]; then
            [ "$l_ldv" -ge "0" -a "$l_ldv" -le "$l_ldmv" ] && l_output="$l_output\n - Parâmetro \"lock-delay\" configurado para $l_ldv segundos em \"$l_kfile\""
            [ "$l_ldv" -gt "$l_ldmv" ] && l_output2="$l_output2\n - Parâmetro \"lock-delay\" com valor alto ($l_ldv > $l_ldmv) em \"$l_kfile\""
         else
            l_output2="$l_output2\n - Parâmetro \"lock-delay\" não configurado em \"$l_kfile\""
         fi

         if grep -Psq "^\h*system-db:$l_profile" /etc/dconf/profile/*; then
            l_output="$l_output\n - O profile \"$l_profile\" está declarado em /etc/dconf/profile/"
         else
            l_output2="$l_output2\n - O profile \"$l_profile\" NÃO está declarado em /etc/dconf/profile/"
         fi

         if [ -f "/etc/dconf/db/$l_profile" ]; then
            l_output="$l_output\n - O banco \"$l_profile\" existe em /etc/dconf/db/"
         else
            l_output2="$l_output2\n - O banco \"$l_profile\" NÃO existe em /etc/dconf/db/"
         fi
      else
         l_output2="$l_output2\n - Parâmetro \"idle-delay\" não encontrado, demais verificações ignoradas"
      fi
   else
      l_output="$l_output\n - GDM não está instalado\n - Recomendação não se aplica"
   fi

   [ -n "$l_pkgoutput" ] && echo -e "$l_pkgoutput"
   if [ -z "$l_output2" ]; then
      echo -e "\n✅ [APROVADO]: Todas as configurações estão corretas.$l_output"
   else
      echo -e "\n⚠️ [REPROVADO]: Problemas encontrados:$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas:\n$l_output"
   fi
}