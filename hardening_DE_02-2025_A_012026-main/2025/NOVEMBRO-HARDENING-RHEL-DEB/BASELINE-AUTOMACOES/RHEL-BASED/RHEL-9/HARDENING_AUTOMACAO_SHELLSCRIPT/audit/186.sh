#!/usr/bin/env bash
echo -e "[73]	Certifique-se de que a montagem automática de mídia removível do GDM esteja desativada"
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
      l_kfile="$(grep -Prils '^\h*automount\b' /etc/dconf/db/*.d)"
      l_kfile2="$(grep -Prils '^\h*automount-open\b' /etc/dconf/db/*.d)"

      if [ -f "$l_kfile" ]; then
         l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")"
      elif [ -f "$l_kfile2" ]; then
         l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile2")"
      fi

      if [ -n "$l_gpname" ]; then
         l_gpdir="/etc/dconf/db/$l_gpname.d"

         if grep -Pq "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*; then
            l_output+="\n - Perfil \"$l_gpname\" está configurado no dconf (system-db)"
         else
            l_output2+="\n - Perfil \"$l_gpname\" não está referenciado nos arquivos de profile do dconf"
         fi

         if [ -f "/etc/dconf/db/$l_gpname" ]; then
            l_output+="\n - Banco de dados \"$l_gpname\" existe no dconf"
         else
            l_output2+="\n - Banco de dados \"$l_gpname\" não encontrado no dconf"
         fi

         if [ -d "$l_gpdir" ]; then
            l_output+="\n - Diretório \"$l_gpdir\" do perfil existe"
         else
            l_output2+="\n - Diretório \"$l_gpdir\" do perfil não existe"
         fi

         if grep -Pqrs '^\h*automount\s*=\s*false\b' "$l_kfile"; then
            l_output+="\n - \"automount\" está corretamente definido como false em: $l_kfile"
         else
            l_output2+="\n - \"automount\" não está corretamente configurado"
         fi

         if grep -Pqs '^\h*automount-open\s*=\s*false\b' "$l_kfile2"; then
            l_output+="\n - \"automount-open\" está corretamente definido como false em: $l_kfile2"
         else
            l_output2+="\n - \"automount-open\" não está corretamente configurado"
         fi
      else
         l_output2+="\n - Nenhuma configuração encontrada para \"automount\" ou \"automount-open\""
      fi
   else
      l_output+="\n - GDM não está instalado no sistema\n - Recomendação não se aplica"
   fi

   if [ -z "$l_output2" ]; then
      echo -e "\n✅ [APROVADO]: Todas as configurações estão corretas.$l_output"
   else
      echo -e "\n⚠️ [REPROVADO]: Foram encontradas inconsistências:$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas:\n$l_output"
   fi
}