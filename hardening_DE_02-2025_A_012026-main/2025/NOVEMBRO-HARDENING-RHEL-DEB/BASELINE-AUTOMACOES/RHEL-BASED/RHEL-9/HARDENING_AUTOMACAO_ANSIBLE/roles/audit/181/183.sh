#!/usr/bin/env bash
echo "[70]	Certifique-se de que a opção desabilitar lista de usuários do GDM esteja habilitada"
{
   l_pkgoutput=""
   if command -v dpkg-query > /dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm > /dev/null 2>&1; then
      l_pq="rpm -q"
   fi

   l_pcl="gdm gdm3" # Lista de pacotes a verificar
   for l_pn in $l_pcl; do
      $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Pacote: \"$l_pn\" está instalado no sistema\n - Verificando configuração..."
   done

   if [ -n "$l_pkgoutput" ]; then
      output="" output2=""

      # Verifica se a opção disable-user-list está ativada
      l_gdmfile="$(grep -Pril '^\h*disable-user-list\h*=\h*true\b' /etc/dconf/db)"
      if [ -n "$l_gdmfile" ]; then
         output="$output\n - A opção \"disable-user-list\" está ativada em: $l_gdmfile"

         # Extrai nome do perfil
         l_gdmprofile="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_gdmfile")"

         # Verifica se o profile está declarado
         if grep -Pq "^\h*system-db:$l_gdmprofile" /etc/dconf/profile/"$l_gdmprofile"; then
            output="$output\n - O profile \"$l_gdmprofile\" está declarado em /etc/dconf/profile/"
         else
            output2="$output2\n - O profile \"$l_gdmprofile\" NÃO está declarado em /etc/dconf/profile/"
         fi

         # Verifica se o arquivo do profile existe no banco
         if [ -f "/etc/dconf/db/$l_gdmprofile" ]; then
            output="$output\n - O banco \"$l_gdmprofile\" existe em /etc/dconf/db/"
         else
            output2="$output2\n - O banco \"$l_gdmprofile\" NÃO existe em /etc/dconf/db/"
         fi
      else
         output2="$output2\n - A opção \"disable-user-list\" NÃO está ativada"
      fi

      # Resultado
      if [ -z "$output2" ]; then
         echo -e "$l_pkgoutput\n\n✅ [APROVADO]: Todas as verificações estão em conformidade.\n$output"
      else
         echo -e "$l_pkgoutput\n\n⚠️ [REPROVADO]: Foram encontradas falhas na auditoria:\n$output2"
         [ -n "$output" ] && echo -e "\nℹ️ Configurações corretas detectadas:\n$output"
      fi

   else
      echo -e "\n✅ [APROVADO]: O GNOME Display Manager não está instalado. Tópico não se aplica."
   fi
}