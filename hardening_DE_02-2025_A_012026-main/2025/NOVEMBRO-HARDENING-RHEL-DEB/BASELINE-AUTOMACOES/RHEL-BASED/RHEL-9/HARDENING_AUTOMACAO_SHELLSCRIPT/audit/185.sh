#!/usr/bin/env bash
echo -e "[72]	Certifique-se de que os bloqueios de tela do GDM não possam ser substituídos"
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

      l_kfd="/etc/dconf/db/$(grep -Psril '^\h*idle-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"
      l_kfd2="/etc/dconf/db/$(grep -Psril '^\h*lock-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"

      if [ -d "$l_kfd" ]; then
         if grep -Prilq '/org/gnome/desktop/session/idle-delay\b' "$l_kfd"; then
            l_output+="\n - \"idle-delay\" está bloqueado em: $(grep -Pril '/org/gnome/desktop/session/idle-delay\b' "$l_kfd")"
         else
            l_output2+="\n - \"idle-delay\" não está bloqueado"
         fi
      else
         l_output2+="\n - \"idle-delay\" não está configurado, portanto não pode ser bloqueado"
      fi

      if [ -d "$l_kfd2" ]; then
         if grep -Prilq '/org/gnome/desktop/screensaver/lock-delay\b' "$l_kfd2"; then
            l_output+="\n - \"lock-delay\" está bloqueado em: $(grep -Pril '/org/gnome/desktop/screensaver/lock-delay\b' "$l_kfd2")"
         else
            l_output2+="\n - \"lock-delay\" não está bloqueado"
         fi
      else
         l_output2+="\n - \"lock-delay\" não está configurado, portanto não pode ser bloqueado"
      fi
   else
      l_output+="\n - GDM não está instalado no sistema\n - Recomendação não se aplica"
   fi

   [ -n "$l_pkgoutput" ] && echo -e "$l_pkgoutput"
   if [ -z "$l_output2" ]; then
      echo -e "\n✅ [APROVADO]: Todas as configurações estão corretas.$l_output"
   else
      echo -e "\n⚠️ [REPROVADO]: Problemas encontrados:$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas:\n$l_output"
   fi
}
