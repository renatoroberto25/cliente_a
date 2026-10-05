#!/usr/bin/env bash
echo -e "[74]	Certifique-se de que a desativação da montagem automática de mídia removível pelo GDM não seja substituída"
{
   l_pkgoutput="" l_output="" l_output2=""

   if command -v dpkg-query > /dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm > /dev/null 2>&1; then
      l_pq="rpm -q"
   fi

   l_pcl="gdm gdm3"
   for l_pn in $l_pcl; do
      $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput+="\n - Pacote: \"$l_pn\" está instalado\n - Verificando configurações..."
   done

   if [ -n "$l_pkgoutput" ]; then
      echo -e "$l_pkgoutput"
      l_kfd="/etc/dconf/db/$(grep -Psril '^\h*automount\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"
      l_kfd2="/etc/dconf/db/$(grep -Psril '^\h*automount-open\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"

      if [ -d "$l_kfd" ]; then
         if grep -Priq '^\h*\/org/gnome\/desktop\/media-handling\/automount\b' "$l_kfd"; then
            l_output+="\n - \"automount\" está bloqueado em: $(grep -Pril '^\h*\/org/gnome\/desktop\/media-handling\/automount\b' "$l_kfd")"
         else
            l_output2+="\n - \"automount\" não está bloqueado"
         fi
      else
         l_output2+="\n - \"automount\" não está definido, portanto não pode ser bloqueado"
      fi

      if [ -d "$l_kfd2" ]; then
         if grep -Priq '^\h*\/org/gnome\/desktop\/media-handling\/automount-open\b' "$l_kfd2"; then
            l_output+="\n - \"automount-open\" está bloqueado em: $(grep -Pril '^\h*\/org/gnome\/desktop\/media-handling\/automount-open\b' "$l_kfd2")"
         else
            l_output2+="\n - \"automount-open\" não está bloqueado"
         fi
      else
         l_output2+="\n - \"automount-open\" não está definido, portanto não pode ser bloqueado"
      fi

   else
      l_output+="\n - GDM não está instalado no sistema\n - Recomendação não se aplica"
   fi

   if [ -z "$l_output2" ]; then
      echo -e "\n✅ [APROVADO]: Todas as configurações estão corretas.$l_output"
   else
      echo -e "\n⚠️ [REPROVADO]: Foram encontradas inconsistências:$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas:$l_output"
   fi
}