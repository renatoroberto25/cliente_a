#!/usr/bin/env bash
echo "[76] - Garantir que o GDM autorun-never não seja substituído."
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
      # Procura por "autorun-never" para determinar o perfil em uso
      l_kfd="/etc/dconf/db/$(grep -Psril '^\h*autorun-never\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d" # Define o diretorio do arquivo de chave a ser bloqueado

      if [ -d "$l_kfd" ]; then # Se o diretorio do arquivo de chave nao existir, as opcoes nao podem ser bloqueadas
         if grep -Priq '^\h*\/org/gnome\/desktop\/media-handling\/autorun-never\b' "$l_kfd"; then
            echo " - \"autorun-never\" esta bloqueado em \"$(grep -Pril '^\h*\/org/gnome\/desktop\/media-handling\/autorun-never\b' "$l_kfd")\""
         else
            echo " - criando entrada para bloquear \"autorun-never\""
            [ ! -d "$l_kfd"/locks ] && echo " - criando diretorio $l_kfd/locks" && mkdir "$l_kfd"/locks
            {
               echo -e '\n# Bloquear configuracao de autorun-never do desktop'
               echo '/org/gnome/desktop/media-handling/autorun-never'
            } >> "$l_kfd"/locks/00-media-autorun        
         fi
      else
         echo -e " - \"autorun-never\" nao esta configurado, entao nao pode ser bloqueado\n - Siga a remediacao \"Garantir que o GDM tenha o autorun-never habilitado\" e execute esta remediacao novamente"
      fi

      # Atualiza o banco de dados dconf
      dconf update
   else
      echo -e " - O pacote GNOME Desktop Manager nao esta instalado no sistema\n  - Remediacao nao aplicavel."
   fi
}
