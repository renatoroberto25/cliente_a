#!/usr/bin/env bash

{
   l_pkgoutput=""
   if command -v dpkg-query > /dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm > /dev/null 2>&1; then
      l_pq="rpm -q"
   fi
   l_pcl="gdm gdm3" # Lista de pacotes separados por espaco para verificar
   for l_pn in $l_pcl; do
      $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Pacote: \"$l_pn\" existe no sistema\n - verificando configuracao"
   done
   if [ -n "$l_pkgoutput" ]; then

      l_gdmprofile="gdm" # Defina este como o nome do perfil desejado conforme politica local
      l_bmessage="'Uso autorizado apenas. Toda atividade pode ser monitorada e registrada'" # Mensagem de aviso desejada
      if [ ! -f "/etc/dconf/profile/$l_gdmprofile" ]; then
         echo "Criando perfil \"$l_gdmprofile\""
         echo -e "user-db:user\nsystem-db:$l_gdmprofile\nfile-db:/usr/share/$l_gdmprofile/greeter-dconf-defaults" > /etc/dconf/profile/$l_gdmprofile
      fi
      if [ ! -d "/etc/dconf/db/$l_gdmprofile.d/" ]; then
         echo "Criando diretorio do banco de dados dconf \"/etc/dconf/db/$l_gdmprofile.d/\""
         mkdir /etc/dconf/db/$l_gdmprofile.d/
      fi
      if ! grep -Piq '^\h*banner-message-enable\h*=\h*true\b' /etc/dconf/db/$l_gdmprofile.d/*; then
         echo "Criando arquivo de chave do gdm para configuracoes em toda a maquina"
         if ! grep -Piq -- '^\h*banner-message-enable\h*=' /etc/dconf/db/$l_gdmprofile.d/*; then
            l_kfile="/etc/dconf/db/$l_gdmprofile.d/01-banner-message"
            echo -e "\n[org/gnome/login-screen]\nbanner-message-enable=true" >> "$l_kfile"
         else
            l_kfile="$(grep -Pil -- '^\h*banner-message-enable\h*=' /etc/dconf/db/$l_gdmprofile.d/*)"
            ! grep -Pq '^\h*\[org/gnome/login-screen\]' "$l_kfile" && sed -ri '/^\s*banner-message-enable/ i\[org/gnome/login-screen]' "$l_kfile"
            ! grep -Pq '^\h*banner-message-enable\h*=\h*true\b' "$l_kfile" && sed -ri 's/^\s*(banner-message-enable\s*=\s*)(\S+)(\s*.*$)/\1true \3/' "$l_kfile"
         fi
      fi
      if ! grep -Piq "^\h*banner-message-text=['\"]+\S+" "$l_kfile"; then
         sed -ri "/^\s*banner-message-enable/ a\banner-message-text=$l_bmessage" "$l_kfile"
      fi
      dconf update
   else
      echo -e "\n\n - GNOME Desktop Manager nao esta instalado\n - Remediacao nao aplicavel\n - Nenhuma remediacao necessaria\n"
   fi
}
