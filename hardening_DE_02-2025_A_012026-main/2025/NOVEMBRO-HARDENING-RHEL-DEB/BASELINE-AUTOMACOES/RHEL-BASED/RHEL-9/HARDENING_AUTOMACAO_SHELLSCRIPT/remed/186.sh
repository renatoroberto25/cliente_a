#!/usr/bin/env bash
echo "[73] - Certifique-se de que a montagem automática de mídia removível do GDM esteja desabilitada."
{
   l_pkgoutput=""
   l_gpname="local" # Definir o nome do perfil dconf desejado (padrao é local)

   # Verifica se o GNOME Desktop Manager esta instalado. Se o pacote nao estiver instalado, a recomendacao nao se aplica
   # Determina o gerenciador de pacotes do sistema
   if command -v dpkg-query > /dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm > /dev/null 2>&1; then
      l_pq="rpm -q"
   fi

   # Verifica se o GDM esta instalado
   l_pcl="gdm gdm3" # Lista de pacotes separados por espaco para verificar
   for l_pn in $l_pcl; do
      $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Pacote: \"$l_pn\" existe no sistema\n - verificando configuracao"
   done

   # Verifica a configuracao (se aplicavel)
   if [ -n "$l_pkgoutput" ]; then
      echo -e "$l_pkgoutput"

      # Verifica configuracoes existentes e define variaveis se existirem
      l_kfile="$(grep -Prils -- '^\h*automount\b' /etc/dconf/db/*.d)"
      l_kfile2="$(grep -Prils -- '^\h*automount-open\b' /etc/dconf/db/*.d)"

      # Define o nome do perfil com base no diretorio dconf db ({NOME_DO_PERFIL}.d)
      if [ -f "$l_kfile" ]; then
         l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")"
         echo " - atualizando nome do perfil dconf para \"$l_gpname\""
      elif [ -f "$l_kfile2" ]; then
         l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile2")"
         echo " - atualizando nome do perfil dconf para \"$l_gpname\""
      fi

      # Verifica consistencia (limpa configuracao se necessario)
      if [ -f "$l_kfile" ] && [ "$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")" != "$l_gpname" ]; then
         sed -ri "/^\s*automount\s*=/s/^/# /" "$l_kfile"
         l_kfile="/etc/dconf/db/$l_gpname.d/00-media-automount"
      fi
      if [ -f "$l_kfile2" ] && [ "$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile2")" != "$l_gpname" ]; then
         sed -ri "/^\s*automount-open\s*=/s/^/# /" "$l_kfile2"
      fi
      [ -z "$l_kfile" ] && l_kfile="/etc/dconf/db/$l_gpname.d/00-media-automount"

      # Verifica se o arquivo de perfil existe
      if grep -Pq -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*; then
         echo -e "\n - O perfil do banco de dados dconf existe em: \"$(grep -Pl -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*)\""
      else
         if [ ! -f "/etc/dconf/profile/user" ]; then
            l_gpfile="/etc/dconf/profile/user"
         else
            l_gpfile="/etc/dconf/profile/user2"
         fi
         echo -e " - criando perfil do banco de dados dconf"
         {
            echo -e "\nuser-db:user"
            echo "system-db:$l_gpname"
         } >> "$l_gpfile"
      fi

      # Cria o diretorio dconf se nao existir
      l_gpdir="/etc/dconf/db/$l_gpname.d"
      if [ -d "$l_gpdir" ]; then
         echo " - O diretorio do banco de dados dconf \"$l_gpdir\" ja existe"
      else
         echo " - criando diretorio do banco de dados dconf \"$l_gpdir\""
         mkdir "$l_gpdir"
      fi

      # Verifica configuracao de automount-open
      if grep -Pqs -- '^\h*automount-open\h*=\h*false\b' "$l_kfile"; then
         echo " - \"automount-open\" esta definido como false em: \"$l_kfile\""
      else
         echo " - criando entrada \"automount-open\" em \"$l_kfile\""
         ! grep -Psq -- '^\h*\[org\/gnome\/desktop\/media-handling\]\b' "$l_kfile" && echo '[org/gnome/desktop/media-handling]' >> "$l_kfile"
         sed -ri '/^\s*\[org\/gnome\/desktop\/media-handling\]/a \\nautomount-open=false' "$l_kfile"
      fi

      # Verifica configuracao de automount
      if grep -Pqs -- '^\h*automount\h*=\h*false\b' "$l_kfile"; then
         echo " - \"automount\" esta definido como false em: \"$l_kfile\""
      else
         echo " - criando entrada \"automount\" em \"$l_kfile\""
         ! grep -Psq -- '^\h*\[org\/gnome\/desktop\/media-handling\]\b' "$l_kfile" && echo '[org/gnome/desktop/media-handling]' >> "$l_kfile"
         sed -ri '/^\s*\[org\/gnome\/desktop\/media-handling\]/a \\nautomount=false' "$l_kfile"
      fi

      # Atualiza o banco de dados dconf
      dconf update
   else
      echo -e "\n - O pacote GNOME Desktop Manager nao esta instalado no sistema\n  - Remediacao nao aplicavel."
   fi
}
