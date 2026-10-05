#!/usr/bin/env bash
echo "[72] - Garantir que os bloqueios de tela do GDM não possam ser substituídos."

{
   # Verifica se o GNOME Desktop Manager esta instalado. Se o pacote nao estiver instalado, a recomendacao nao se aplica
   # Determinar o gerenciador de pacotes do sistema
   l_pkgoutput=""
   if command -v dpkg-query > /dev/null 2>&1; then
      l_pq="dpkg-query -W"
   elif command -v rpm > /dev/null 2>&1; then
      l_pq="rpm -q"
   fi
   # Verificar se o GDM esta instalado
   l_pcl="gdm gdm3" # Lista de pacotes separados por espaco para verificar
   for l_pn in $l_pcl; do
      $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="y" && echo -e "\n - Pacote: \"$l_pn\" existe no sistema\n - aplicando remediacao se necessario"
   done
   # Verificar configuracao (se aplicavel)
   if [ -n "$l_pkgoutput" ]; then
      # Procurar idle-delay para determinar o perfil em uso, necessario para os testes seguintes
      l_kfd="/etc/dconf/db/$(grep -Psril '^\h*idle-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"
      # Procurar lock-delay para determinar o perfil em uso, necessario para os testes seguintes
      l_kfd2="/etc/dconf/db/$(grep -Psril '^\h*lock-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"
      if [ -d "$l_kfd" ]; then
         if grep -Prilq '^\h*\/org\/gnome\/desktop\/session\/idle-delay\b' "$l_kfd"; then
            echo " - \"idle-delay\" esta travado em \"$(grep -Pril '^\h*\/org\/gnome\/desktop\/session\/idle-delay\b' "$l_kfd")\""
         else
            echo "criando entrada para travar \"idle-delay\""
            [ ! -d "$l_kfd"/locks ] && echo "criando diretorio $l_kfd/locks" && mkdir "$l_kfd"/locks
            {
               echo -e '\n# Travar configuracao de idle-delay do protetor de tela'
               echo '/org/gnome/desktop/session/idle-delay'
            } >> "$l_kfd"/locks/00-screensaver        
         fi
      else
         echo -e " - \"idle-delay\" nao esta definido entao nao pode ser travado\n - Por favor, siga a remediacao \"Garantir que a tela bloqueie quando o usuario estiver inativo\" e depois execute este script novamente"
      fi
      if [ -d "$l_kfd2" ]; then
         if grep -Prilq '^\h*\/org\/gnome\/desktop\/screensaver\/lock-delay\b' "$l_kfd2"; then
            echo " - \"lock-delay\" esta travado em \"$(grep -Pril '^\h*\/org\/gnome\/desktop\/screensaver\/lock-delay\b' "$l_kfd2")\""
         else
            echo "criando entrada para travar \"lock-delay\""
            [ ! -d "$l_kfd2"/locks ] && echo "criando diretorio $l_kfd2/locks" && mkdir "$l_kfd2"/locks
            {
               echo -e '\n# Travar configuracao de lock-delay do protetor de tela'
               echo '/org/gnome/desktop/screensaver/lock-delay'
            } >> "$l_kfd2"/locks/00-screensaver       
         fi
      else
         echo -e " - \"lock-delay\" nao esta definido entao nao pode ser travado\n - Por favor, siga a remediacao \"Garantir que a tela bloqueie quando o usuario estiver inativo\" e depois execute este script novamente"
      fi
   else
      echo -e " - Pacote GNOME Desktop Manager nao esta instalado no sistema\n  - Remediacao nao aplicavel."
   fi
}
