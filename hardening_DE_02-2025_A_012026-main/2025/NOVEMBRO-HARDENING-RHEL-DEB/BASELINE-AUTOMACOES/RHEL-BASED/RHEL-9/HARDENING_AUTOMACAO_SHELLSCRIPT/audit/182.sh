#!/usr/bin/env bash
echo "[69]	Certifique-se de que o banner de login do GDM esteja configurado"
{
   l_pkgoutput=""
   if command -v dpkg-query > /dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm > /dev/null 2>&1; then
      l_pq="rpm -q"
   fi

   l_pcl="gdm gdm3" # Lista de pacotes a verificar
   for l_pn in $l_pcl; do
      $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput - Pacote: \"$l_pn\" está instalado no sistema. Verificando configurações..."
   done

   if [ -n "$l_pkgoutput" ]; then
      l_output="" l_output2=""
      echo -e "$l_pkgoutput"

      # Verifica o arquivo com a configuração do banner
      l_gdmfile="$(grep -Prils '^\h*banner-message-enable\b' /etc/dconf/db/*.d)"
      if [ -n "$l_gdmfile" ]; then
         l_gdmprofile="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_gdmfile")"

         # Verifica se o banner está habilitado
         if grep -Pisq '^\h*banner-message-enable=true\b' "$l_gdmfile"; then
            l_output="$l_output\n - A opção \"banner-message-enable\" está habilitada em: $l_gdmfile"
         else
            l_output2="$l_output2\n - A opção \"banner-message-enable\" NÃO está habilitada"
         fi

         # Verifica se o texto do banner está definido
         l_lsbt="$(grep -Pios '^\h*banner-message-text=.*$' "$l_gdmfile")"
         if [ -n "$l_lsbt" ]; then
            l_output="$l_output\n - A opção \"banner-message-text\" está definida em: $l_gdmfile\n   ➥ $l_lsbt"
         else
            l_output2="$l_output2\n - A opção \"banner-message-text\" NÃO está definida"
         fi

         # Verifica se o profile existe
         if grep -Pq "^\h*system-db:$l_gdmprofile" /etc/dconf/profile/"$l_gdmprofile"; then
            l_output="$l_output\n - O perfil \"$l_gdmprofile\" existe em /etc/dconf/profile/"
         else
            l_output2="$l_output2\n - O perfil \"$l_gdmprofile\" NÃO existe em /etc/dconf/profile/"
         fi

         # Verifica se o perfil existe no banco do dconf
         if [ -f "/etc/dconf/db/$l_gdmprofile" ]; then
            l_output="$l_output\n - O banco dconf \"$l_gdmprofile\" existe em /etc/dconf/db/"
         else
            l_output2="$l_output2\n - O banco dconf \"$l_gdmprofile\" NÃO existe em /etc/dconf/db/"
         fi

      else
         l_output2="$l_output2\n - A opção \"banner-message-enable\" NÃO está configurada"
      fi

   else
      echo -e "✅ [APROVADO]: O GNOME Display Manager não está instalado. Tópico não se aplica."
   fi

   if [ -z "$l_output2" ]; then
      echo -e "\n✅ [APROVADO]: Todas as verificações estão em conformidade."
      echo -e "$l_output"
   else
      echo -e "\n⚠️ [REPROVADO]: Foram encontradas falhas na auditoria:"
      echo -e "$l_output2"
      [ -n "$l_output" ] && echo -e "\nℹ️ Configurações corretas detectadas:\n$l_output"
   fi
}