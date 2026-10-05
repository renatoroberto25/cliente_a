#!/usr/bin/env bash

echo " [171] Restringir o acesso ao comando su usando pam_wheel e grupo dedicado"

GRUPO_SU="sugroup"
PAM_SU="/etc/pam.d/su"
LINHA_CONF="auth required pam_wheel.so use_uid group=$GRUPO_SU"

# Cria grupo se não existir
if getent group "$GRUPO_SU" >/dev/null; then
  echo "✅ Grupo '$GRUPO_SU' já existe"
else
  groupadd "$GRUPO_SU"
  echo "✅ Grupo '$GRUPO_SU' criado"
fi

# Verifica e adiciona configuração no /etc/pam.d/su
if grep -Fq "$LINHA_CONF" "$PAM_SU"; then
  echo "✅ Linha de restrição já presente em $PAM_SU"
else
  cp -p "$PAM_SU" "$PAM_SU.bak.$(date +%Y%m%d%H%M%S)"
  echo "$LINHA_CONF" >> "$PAM_SU"
  echo "✅ Linha adicionada ao $PAM_SU para restringir o uso do su (backup criado)"
fi

echo -e "\n✅ Remediação finalizada"
exit 0