#!/usr/bin/env bash
echo -e "[76] Certifique-se de que o GDM autorun-never não seja substituído"
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

      l_kfd="/etc/dconf/db/$(grep -Psril '^\h*autorun-never\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"

      if [ -d "$l_kfd" ]; then
         if grep -Priq '^\h*/org/gnome/desktop/media-handling/autorun-never\b' "$l_kfd"; then
            l_output+="\n - \"autorun-never\" está bloqueado em: $(grep -Pril '^\h*/org/gnome/desktop/media-handling/autorun-never\b' "$l_kfd")"
         else
            l_output2+="\n - \"autorun-never\" não está bloqueado corretamente"
         fi
      else
         l_output2+="\n - \"autorun-never\" não está definido, portanto não pode ser bloqueado"
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