#!/usr/bin/env bash
echo -e "[75] Certifique-se de que o GDM autorun-never esteja ativado"
{
   l_pkgoutput="" l_output="" l_output2=""

   # Verifica o gerenciador de pacotes
   if command -v dpkg-query > /dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm > /dev/null 2>&1; then
      l_pq="rpm -q"
   fi

   # Verifica se o GDM está instalado
   l_pcl="gdm gdm3"
   for l_pn in $l_pcl; do
      $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput+="\n - Pacote: \"$l_pn\" está instalado\n - Verificando configurações..."
   done

   if [ -n "$l_pkgoutput" ]; then
      echo -e "$l_pkgoutput"

      l_kfile="$(grep -Prils -- '^\h*autorun-never\b' /etc/dconf/db/*.d)"
      if [ -f "$l_kfile" ]; then
         l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")"
      fi

      if [ -n "$l_gpname" ]; then
         l_gpdir="/etc/dconf/db/$l_gpname.d"

         if grep -Pq -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*; then
            l_output+="\n - Arquivo de perfil do banco dconf existe: $(grep -Pl -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*)"
         else
            l_output2+="\n - Arquivo de perfil do banco dconf não está definido"
         fi

         if [ -f "/etc/dconf/db/$l_gpname" ]; then
            l_output+="\n - O banco dconf \"$l_gpname\" existe"
         else
            l_output2+="\n - O banco dconf \"$l_gpname\" não existe"
         fi

         if [ -d "$l_gpdir" ]; then
            l_output+="\n - O diretório \"$l_gpdir\" do dconf existe"
         else
            l_output2+="\n - O diretório \"$l_gpdir\" do dconf não existe"
         fi

         if grep -Pqrs -- '^\h*autorun-never\h*=\h*true\b' "$l_kfile"; then
            l_output+="\n - \"autorun-never\" está definido como true em: \"$l_kfile\""
         else
            l_output2+="\n - \"autorun-never\" não está corretamente definido"
         fi
      else
         l_output2+="\n - \"autorun-never\" não está configurado"
      fi
   else
      l_output+="\n - GNOME Desktop Manager não está instalado\n - Recomendação não se aplica"
   fi

   # Resultado final
   if [ -z "$l_output2" ]; then
      echo -e "\n✅ [APROVADO]: Todas as configurações estão corretas.$l_output"
   else
      echo -e "\n⚠️ [REPROVADO]: Foram encontradas inconsistências:$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas:$l_output"
   fi
}