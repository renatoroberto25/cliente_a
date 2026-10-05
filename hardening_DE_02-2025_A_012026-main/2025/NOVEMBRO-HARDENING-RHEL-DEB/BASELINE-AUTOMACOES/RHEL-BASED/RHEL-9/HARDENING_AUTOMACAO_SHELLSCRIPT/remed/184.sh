#!/usr/bin/env bash
echo "[71] - GDM tempo deinatividade antes da tela apagar"
{
   l_key_file="/etc/dconf/db/local.d/00-screensaver"
   l_idmv="900" # Maximo de segundos de inatividade antes de desligar a tela
   l_ldmv="5"   # Maximo de segundos apos a tela desligar ate bloquear

   # Criar o diretorio se ele nao existir
   mkdir -p "$(dirname "$l_key_file")"

   {
      echo '# Especificar o caminho do dconf'
      echo '[org/gnome/desktop/session]'
      echo ''
      echo '# Numero de segundos de inatividade antes da tela apagar'
      echo '# Defina como 0 segundos se quiser desativar o protetor de tela.'
      echo "idle-delay=uint32 $l_idmv"
      echo ''
      echo '# Especificar o caminho do dconf'
      echo '[org/gnome/desktop/screensaver]'
      echo ''
      echo '# Numero de segundos apos a tela apagar antes de bloquear a tela'
      echo "lock-delay=uint32 $l_ldmv"
   } > "$l_key_file"

   # Atualizar banco de dados do dconf
   if command -v dconf >/dev/null 2>&1; then
      echo "Executando dconf update"
      dconf update
   else
      echo "Comando dconf nao encontrado."
   fi
}
