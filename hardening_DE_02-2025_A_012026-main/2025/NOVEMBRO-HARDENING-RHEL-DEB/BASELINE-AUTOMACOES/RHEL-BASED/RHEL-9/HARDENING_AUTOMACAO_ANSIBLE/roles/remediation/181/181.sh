#!/usr/bin/env bash
echo "68 Ensure GNOME Display Manager is removed"
# Verifica se o GDM está instalado
if rpm -qa gdm > /dev/null 2>&1; then
  # Remove o GDM
  sudo dnf remove gdm -y
  if [ $? -eq 0 ]; then
    echo " - GDM removido."
  else
    echo " - Falha ao remover GDM."
    exit 1
  fi
else
  echo " - GDM não instalado. Nesse caso os subtópicos de 2 a 9 podem ser desconsiderados."
fi

exit 0