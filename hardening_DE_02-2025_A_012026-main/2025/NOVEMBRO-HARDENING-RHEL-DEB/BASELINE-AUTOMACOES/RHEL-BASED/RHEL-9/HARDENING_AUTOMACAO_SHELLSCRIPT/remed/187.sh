#!/usr/bin/env bash
echo "[74] - Garantir que a desativação da montagem automática de mídia removível do GDM não seja substituída."
{
   # Verifica se o GNOME Desktop Manager esta instalado. Se o pacote nao estiver instalado, a recomendacao nao se aplica
   # Determina o gerenciador de pacotes do sistema
   l_pkgoutput=""
   if command -v dpkg-query > /dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm > /dev/null 2>&1; then
      l_pq="rpm -q"
   fi

   # Verifica se o GDM esta instalado
   l_pcl="gdm gdm3" # Lista de pacotes separados por espaco para verificar
   for l_pn in $l_pcl; do
      $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="y" && echo -e "\n - Pacote: \"$l_pn\" existe no sistema\n - remediando configuracao se necessario"
   done

   # Verifica a configuracao (se aplicavel)
   if [ -n "$l_pkgoutput" ]; then
      # Procura por "automount" para determinar o perfil em uso, necessario para os testes seguintes
      l_kfd="/etc/dconf/db/$(grep -Psril '^\h*automount\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d" # Define o diretorio do arquivo de chave a ser bloqueado

      # Procura por "automount-open" para determinar o perfil em uso, necessario para os testes seguintes
      l_kfd2="/etc/dconf/db/$(grep -Psril '^\h*automount-open\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d" # Define o diretorio do arquivo de chave a ser bloqueado

      if [ -d "$l_kfd" ]; then # Se o diretorio nao existir, as opcoes nao podem ser bloqueadas
         if grep -Priq '^\h*\/org/gnome\/desktop\/media-handling\/automount\b' "$l_kfd"; then
            echo " - \"automount\" esta bloqueado em \"$(grep -Pril '^\h*\/org/gnome\/desktop\/media-handling\/automount\b' "$l_kfd")\""
         else
            echo " - criando entrada para bloquear \"automount\""
            [ ! -d "$l_kfd"/locks ] && echo " - criando diretorio $l_kfd/locks" && mkdir "$l_kfd"/locks
            {
               echo -e '\n# Bloquear configuracao de automount do desktop'
               echo '/org/gnome/desktop/media-handling/automount'
            } >> "$l_kfd"/locks/00-media-automount        
         fi
      else
         echo -e " - \"automount\" nao esta configurado, entao nao pode ser bloqueado\n - Siga a remediacao \"Garantir que o GDM nao monte midias removiveis automaticamente\" e execute esta remediacao novamente"
      fi

      if [ -d "$l_kfd2" ]; then
         if grep -Priq '^\h*\/org/gnome\/desktop\/media-handling\/automount-open\b' "$l_kfd2"; then
            echo " - \"automount-open\" esta bloqueado em \"$(grep -Pril '^\h*\/org/gnome\/desktop\/media-handling\/automount-open\b' "$l_kfd2")\""
         else
            echo " - criando entrada para bloquear \"automount-open\""
            [ ! -d "$l_kfd2"/locks ] && echo " - criando diretorio $l_kfd2/locks" && mkdir "$l_kfd2"/locks
            {
               echo -e '\n# Bloquear configuracao de automount-open do desktop'
               echo '/org/gnome/desktop/media-handling/automount-open'
            } >> "$l_kfd2"/locks/00-media-automount
         fi
      else
         echo -e " - \"automount-open\" nao esta configurado, entao nao pode ser bloqueado\n - Siga a remediacao \"Garantir que o GDM nao monte midias removiveis automaticamente\" e execute esta remediacao novamente"
      fi

      # Atualiza o banco de dados dconf
      dconf update
   else
      echo -e " - O pacote GNOME Desktop Manager nao esta instalado no sistema\n  - Remediacao nao aplicavel."
   fi
}
