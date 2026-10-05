#!/usr/bin/env bash

{
   l_pkgoutput="" 
   l_output="" 
   l_output2=""
   l_gpname="local" # Nome padrão do perfil dconf

   # Determinar gerenciador de pacotes
   if command -v dpkg-query >/dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm >/dev/null 2>&1; then
      l_pq="rpm -q"
   else
      echo " - Nenhum gerenciador de pacotes compatível encontrado. Saindo."
      exit 0
   fi

   # Verificar se o GDM está instalado
   for l_pn in gdm gdm3; do
      if $l_pq "$l_pn" >/dev/null 2>&1; then
         l_pkgoutput="$l_pkgoutput\n - Pacote \"$l_pn\" está instalado\n - Verificando configuração"
         break
      fi
   done

   # Caso GDM não esteja instalado, sair
   if [ -z "$l_pkgoutput" ]; then
      echo -e "\n - GNOME Desktop Manager (GDM) não está instalado no sistema"
      echo "  - Recomendação não aplicável"
      exit 0
   fi

   echo -e "$l_pkgoutput"

   # Verificar se o comando dconf existe
   if ! command -v dconf >/dev/null 2>&1; then
      echo " - Comando 'dconf' não encontrado. Saindo sem aplicar alterações."
      exit 0
   fi

   # Localizar arquivo existente com a chave autorun-never
   l_kfile="$(grep -Prils -- '^\h*autorun-never\b' /etc/dconf/db/*.d 2>/dev/null)"

   # Se encontrou, extrair o nome do perfil
   if [ -f "$l_kfile" ]; then
      l_gpname="$(awk -F/ '{split($(NF-1),a,"."); print a[1]}' <<< "$l_kfile")"
      echo " - Atualizando nome do perfil dconf para \"$l_gpname\""
   fi

   # Garantir existência do arquivo de configuração
   [ -z "$l_kfile" ] && l_kfile="/etc/dconf/db/$l_gpname.d/00-media-autorun"

   # Verificar se o perfil existe
   if grep -Pq -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/* 2>/dev/null; then
      echo -e "\n - Perfil dconf encontrado em: $(grep -Pl -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*)"
   else
      l_gpfile="/etc/dconf/profile/user"
      [ -f "$l_gpfile" ] || l_gpfile="/etc/dconf/profile/user2"
      echo " - Criando perfil dconf \"$l_gpfile\""
      echo -e "\nuser-db:user\nsystem-db:$l_gpname" >> "$l_gpfile"
   fi

   # Criar diretório do perfil se necessário
   l_gpdir="/etc/dconf/db/$l_gpname.d"
   if [ ! -d "$l_gpdir" ]; then
      echo " - Criando diretório \"$l_gpdir\""
      mkdir -p "$l_gpdir"
   else
      echo " - Diretório \"$l_gpdir\" já existe"
   fi

   # Configurar chave autorun-never
   if grep -Pqs -- '^\h*autorun-never\h*=\h*true\b' "$l_kfile"; then
      echo " - \"autorun-never\" já está definido como true em: \"$l_kfile\""
   else
      echo " - Criando ou atualizando entrada \"autorun-never\" em \"$l_kfile\""
      if grep -Psq -- '^\h*autorun-never' "$l_kfile"; then
         sed -ri 's/(^\s*autorun-never\s*=\s*)(\S+)(\s*.*)$/\1true \3/' "$l_kfile"
      else
         grep -Psq -- '^\h*\[org/gnome/desktop/media-handling\]' "$l_kfile" || echo '[org/gnome/desktop/media-handling]' >> "$l_kfile"
         sed -ri '/^\s*\[org\/gnome\/desktop\/media-handling\]/a autorun-never=true' "$l_kfile"
      fi
   fi

   # Atualizar banco dconf
   echo " - Executando dconf update"
   dconf update
}
