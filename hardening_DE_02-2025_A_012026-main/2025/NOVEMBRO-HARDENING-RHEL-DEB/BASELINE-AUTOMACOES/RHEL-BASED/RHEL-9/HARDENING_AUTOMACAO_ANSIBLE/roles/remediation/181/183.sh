#!/usr/bin/env bash

# Verificar se o GDM esta instalado (para sistemas baseados em RPM ou DPKG)
if ! rpm -q gdm &>/dev/null && ! dpkg -s gdm &>/dev/null && \
   ! rpm -q gdm3 &>/dev/null && ! dpkg -s gdm3 &>/dev/null; then
   echo "GDM nao esta instalado. Saindo sem aplicar configuracoes."
   exit 0
fi

# Verificar se o comando dconf existe
if ! command -v dconf >/dev/null 2>&1; then
   echo "Comando 'dconf' nao encontrado. Saindo sem aplicar configuracoes."
   exit 0
fi

l_gdmprofile="gdm"

# Criar perfil do GDM se necessario
if [ ! -f "/etc/dconf/profile/$l_gdmprofile" ]; then
   echo "Criando perfil \"$l_gdmprofile\""
   echo -e "user-db:user\nsystem-db:$l_gdmprofile\nfile-db:/usr/share/$l_gdmprofile/greeter-dconf-defaults" > /etc/dconf/profile/$l_gdmprofile
fi

# Criar diretorio de configuracao do dconf se necessario
if [ ! -d "/etc/dconf/db/$l_gdmprofile.d/" ]; then
   echo "Criando diretorio dconf \"/etc/dconf/db/$l_gdmprofile.d/\""
   mkdir -p /etc/dconf/db/$l_gdmprofile.d/
fi

# Adicionar ou ajustar a configuracao disable-user-list
if ! grep -Piq '^\h*disable-user-list\h*=\h*true\b' /etc/dconf/db/$l_gdmprofile.d/* 2>/dev/null; then
   echo "Criando ou ajustando keyfile do GDM para esconder lista de usuarios"
   if ! grep -Piq -- '^\h*\[org/gnome/login-screen\]' /etc/dconf/db/$l_gdmprofile.d/* 2>/dev/null; then
      echo -e "\n[org/gnome/login-screen]\n# Nao mostrar a lista de usuarios\ndisable-user-list=true" >> /etc/dconf/db/$l_gdmprofile.d/00-login-screen
   else
      sed -ri '/^\s*\[org\/gnome\/login-screen\]/ a\# Nao mostrar a lista de usuarios\ndisable-user-list=true' $(grep -Pil -- '^\h*\[org\/gnome\/login-screen\]' /etc/dconf/db/$l_gdmprofile.d/*)
   fi
fi

# Atualizar banco de dados dconf
echo "Atualizando dconf..."
dconf update
